import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import 'models.dart';
import 'ad_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_rules_dialog.dart';
import 'audio_manager.dart';
import 'event_message_dialog.dart';
import 'package:flutter/services.dart';


class GameScreen extends StatefulWidget {
  final List<String> playerNames;

  GameScreen({required this.playerNames});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late List<PlayerData> players;
  late int currentPlayerIndex;
  int? diceRoll;
  bool diceRolling = false;
  String message = "";
  bool gameOver = false;
  String? winnerId;
  PawnState? selectedPawn;
  late Map<String, String> pawnImages;
  final Random random = Random();
  final List<String> aiNames = ['CobraBot', 'Laddie', 'DiceMaster'];
  late AudioManager audioManager;
  late AnimationController diceGlowAnimationController;
  late Animation<double> diceGlowAnimation;

  bool diceButtonDisabled = false;  // Feature 2: Disable dice button
  bool diceShouldGlow = false;  // Feature 3: Glow dice button

  bool isDirectAnimation = false;  // True for ladders/snakes (Feature 4)
  Duration pawnAnimationDuration = Duration(milliseconds: 500);


  late AnimationController jumpAnimationController;
  late Animation<double> jumpAnimation;
  bool canRollDice = true;
  bool showPauseMenu = false;
  bool hasShownAdThisSession = false;

  // Animation properties
  late AnimationController moveAnimationController;
  late Animation<double> moveAnimation;
  int animationStartPosition = 0;
  int animationEndPosition = 0;
  PawnState? animatingPawn;
  String specialSquareMessage = "";
  bool showSpecialMessage = false;
  Timer? messageTimer;

  @override
  void initState() {
    super.initState();

    audioManager = AudioManager();
    audioManager.init().then((_) {
      audioManager.playGameStart();  // Play start sound
      audioManager.playBackgroundMusic();  // Start background music
    });

    initializePawnImages();
    initializeAnimations();
    startNewGame();

    Future.delayed(Duration(milliseconds: 500), () {
      showGameRulesAtStartup();
    });

    _showRulesDialogIfFirstTime();
  }

  void showGameRulesAtStartup() {
    showGameRulesDialog(context);  // Uses existing game_rules_dialog.dart
  }

  @override
  void dispose() {
    moveAnimationController.dispose();
    jumpAnimationController.dispose();
    diceGlowAnimationController.dispose();
    messageTimer?.cancel();
    audioManager.stopBackgroundMusic();
    audioManager.cleanup();
    super.dispose();
  }

  Future<void> _showRulesDialogIfFirstTime() async {
    // Wait a moment for the game screen to fully load
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final hasSeenRules = prefs.getBool('has_seen_game_rules') ?? false;


    /*
    if (!hasSeenRules && mounted) {
      // Show the dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const GameRulesDialog(),
      );

      // Mark as seen
      await prefs.setBool('has_seen_game_rules', true);
    }
    */
  }

  void initializeAnimations() {
    moveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    moveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: moveAnimationController,
      curve: Curves.easeInOut,
    ));

    diceGlowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 1.5 second pulse
    );

    diceGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: diceGlowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    jumpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    jumpAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: jumpAnimationController,
      curve: Curves.bounceOut,
    ));

    moveAnimationController.addListener(() {
      setState(() {
        if (animatingPawn != null) {
          animatingPawn!.displayPosition = animationStartPosition + 
              ((animationEndPosition - animationStartPosition) * moveAnimation.value).round();
        }
      });
    });

    moveAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        completeMoveAnimation();
      }
    });
  }

  void initializePawnImages() {
    pawnImages = <String, String>{};
    final colors = ['blue', 'red', 'yellow', 'green'];
    
    for (int i = 0; i < widget.playerNames.length; i++) {
      if (i < colors.length) {
        pawnImages[widget.playerNames[i]] = 'assets/pawn_${colors[i]}.png';
      } else {
        pawnImages[widget.playerNames[i]] = 'assets/pawn_blue.png';
      }
    }
  }

  bool isAI(String playerId) {
    return aiNames.contains(playerId);
  }

  void startNewGame() {
    players = [];
    for (int i = 0; i < widget.playerNames.length; i++) {
      players.add(PlayerData(
        id: widget.playerNames[i],
        pawns: List.generate(Constants.pawnsPerPlayer, (index) => PawnState(index, 0)),
        coins: 0,
        skipTurn: false,
        showSkipDialog: false,
      ));
    }

    currentPlayerIndex = 0;
    diceRoll = null;
    diceRolling = false;
    selectedPawn = null;
    gameOver = false;
    winnerId = null;
    message = "${players[currentPlayerIndex].id}'s turn!";

    if (isAI(players[currentPlayerIndex].id)) {
      Future.delayed(Duration(seconds: 1), () => aiPlayTurn());
    }
  }

  void showMessage(String message, {Duration duration = const Duration(seconds: 2)}) {
    HapticFeedback.lightImpact();
    setState(() {
      specialSquareMessage = message;
      showSpecialMessage = true;
    });

    messageTimer?.cancel();
    messageTimer = Timer(duration, () {
      setState(() {
        showSpecialMessage = false;
      });
    });
  }

  void celebratePawnReaching100(PawnState pawn, PlayerData player) {
    audioManager.playWinCracker();
    audioManager.pauseMusic();
    showEventDialog(
      context: context,
      title: '🎉 WINNER! 🎉',
      message: '${player.id} reached 100!\n\nCongratulations!',
      icon: Icons.celebration,
      titleColor: Colors.purple,
      duration: const Duration(seconds: 8),
      onClose: () {
        audioManager.resumeMusic();  // Resume background music
      },
    );
    HapticFeedback.heavyImpact();

  }

  void animatePawnMove(PawnState pawn, int targetPosition) {
    setState(() {
      animatingPawn = pawn;
      animationStartPosition = pawn.displayPosition;
      animationEndPosition = targetPosition;
      pawn.isAnimating = true;
    });

    // ========== Feature 4 & 5: Smart animation duration ==========
    if (isDirectAnimation) {
      // Direct jump for snake/ladder (Feature 4)
      moveAnimationController.duration = Duration(milliseconds: 800);
      audioManager.playSnakeSlide();  // Play sound
    } else {
      // Square-by-square for normal movement (Feature 5)
      int distance = (targetPosition - pawn.displayPosition).abs();
      moveAnimationController.duration = Duration(milliseconds: 100 * distance);
    }

    moveAnimationController.reset();
    moveAnimationController.forward();
  }

  void completeMoveAnimation() {
    if (animatingPawn != null) {
      setState(() {
        // CRITICAL: Ensure both position fields are synchronized
        animatingPawn!.position = animationEndPosition;
        animatingPawn!.displayPosition = animationEndPosition;
        animatingPawn!.isAnimating = false;

        final currentPlayer = players[currentPlayerIndex];

        if (animationEndPosition == Constants.winningSquare) {
          celebratePawnReaching100(animatingPawn!, currentPlayer);
        }
      });

      // Store reference before clearing
      final movedPawn = animatingPawn;

      setState(() {
        animatingPawn = null;
      });



      checkSpecialSquares();

      setState(() {
        canRollDice = true;
        diceButtonDisabled = false;
        diceShouldGlow = true;
        diceGlowAnimationController.repeat();
        canRollDice = true; // delete if not require
      });
    }
  }

  void checkSpecialSquares() {
    final currentPlayer = players[currentPlayerIndex];
    final pawn = currentPlayer.pawns.firstWhere((p) => p.position == animationEndPosition);

    if (animationEndPosition == Constants.winningSquare) {
      celebratePawnReaching100(pawn, currentPlayer);
      return;
    }

    // Check for snakes and ladders FIRST
    if (Constants.snacksAndLaddersMap.containsKey(pawn.position)) {
      int oldPos = pawn.position;
      int newPos = Constants.snacksAndLaddersMap[pawn.position]!;

      if (newPos > oldPos) {
        currentPlayer.coins += Constants.ladderBonus;
        audioManager.playLadderClimb();
        showEventDialog(
          context: context,
          title: ' 目 Ladder!',
          message: 'Climbed a ladder from $oldPos to $newPos!',
          icon: Icons.trending_up,
          titleColor: Colors.green,
          duration: const Duration(seconds: 5),
        );
        HapticFeedback.mediumImpact();
      } else {
        currentPlayer.coins += Constants.snackPenalty;
        if (currentPlayer.coins < 0) currentPlayer.coins = 0;
        audioManager.playSnakeSlide();
        showEventDialog(
          context: context,
          title: '🐍 Snake!',
          message: 'Got bitten! Slid from $oldPos to $newPos!',
          icon: Icons.trending_down,
          titleColor: Colors.red,
          duration: const Duration(seconds: 5),
        );
        HapticFeedback.heavyImpact();
      }

      Future.delayed(Duration(seconds: 1), () {
        animatePawnMove(pawn, newPos);
      });
      return;
    }

    // Gold mine squares give extra turn
    if (Constants.goldMineSquares.contains(pawn.position)) {

      currentPlayer.coins += Constants.goldBonus;
      audioManager.playGoldMine();
      showEventDialog(
        context: context,
        title: '💰 Gold Mine!',
        message: 'Found a gold mine!\nGet an extra turn!',
        icon: Icons.star,
        titleColor: Colors.amber,
        duration: const Duration(seconds: 6),
      );
      HapticFeedback.lightImpact();

      // CRITICAL FIX: Ensure position is correctly synchronized
      setState(() {
        pawn.position = animationEndPosition;
        pawn.displayPosition = animationEndPosition;
      });

      // Give extra turn - don't call nextTurn()
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          canRollDice = true;
          message = '${currentPlayer.id} gets an extra turn! Roll the dice again.';
        });


        // If it's an AI player, automatically start their extra turn
        if (isAI(currentPlayer.id)) {
          Future.delayed(Duration(seconds: 1), () {
            aiPlayTurn();
          });
        }
      });
      return; // CRITICAL: This prevents moving to next player
    }

    // Handle big hole squares
    if (Constants.bigHoleSquares.contains(pawn.position)) {
      currentPlayer.skipTurn = true;
      showEventDialog(
        context: context,
        title: '🕳️ Hole!',
        message: '${currentPlayer.id} fell into a hole! Will skip next turn.',
        icon: Icons.trending_up,
        titleColor: Colors.green,
        duration: const Duration(seconds: 5),
      );
      //showMessage("${currentPlayer.id} fell into a hole! Will skip next turn. 🕳️");
      HapticFeedback.heavyImpact();
      checkForWinner();
      if (!gameOver) {
        Future.delayed(Duration(seconds: 2), () => nextTurn());
      }
      return;
    }

    // Regular squares - proceed to next turn
    checkForWinner();
    if (!gameOver) {
      Future.delayed(Duration(seconds: 2), () => nextTurn());
    }
  }

  void checkForWinner() {
    final currentPlayer = players[currentPlayerIndex];
    bool allPawnsFinished = currentPlayer.pawns.every((pawn) => pawn.position == Constants.winningSquare);

    if (allPawnsFinished) {
      winnerId = winnerId ?? currentPlayer.id;
      setState(() {
        winnerId = currentPlayer.id;
        gameOver = false;
        showEventDialog(
          context: context,
          title: 'Win!',
          message: '${currentPlayer.id} has finished all pawns! 🎉',
          icon: Icons.accessibility,
          titleColor: Colors.green,
          duration: const Duration(seconds: 5),
        );
        //showMessage("${currentPlayer.id} has finished all pawns! 🎉", duration: Duration(seconds: 3));
      });
    }

    bool allPlayersFinished = players.every((player) => 
        player.pawns.every((pawn) => pawn.position == Constants.winningSquare));

    if (allPlayersFinished) {
      setState(() {
        gameOver = true;
        showEventDialog(
          context: context,
          title: 'Game Over!',
          message: 'Game Over! ${winnerId ?? 'No one'} wins! 🏆',
          icon: Icons.trending_up,
          titleColor: Colors.green,
          duration: const Duration(seconds: 5),
        );
        //showMessage("Game Over! ${winnerId ?? 'No one'} wins! 🏆", duration: Duration(seconds: 5));
      });

      // Show interstitial ad when game ends
      Future.delayed(Duration(seconds: 3), () {
        if (!hasShownAdThisSession) {
          hasShownAdThisSession = true;
          AdManager.instance.showInterstitialAd();
        }
      });
    }
  }

  void rollDice() {
    if (diceRolling || gameOver || !canRollDice) return;
      audioManager.playDiceRoll();
    setState(() {
      diceButtonDisabled = true;
      diceShouldGlow = false;
      diceGlowAnimationController.stop();
    });

    if (isAI(players[currentPlayerIndex].id)) return;

    if (diceRoll != null && moveablePawns.isNotEmpty) {
      setState(() {
        message = "Please move a valid pawn before rolling again.";
      });
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      diceRolling = true;
      canRollDice = false;
      diceRoll = null;
      message = "${players[currentPlayerIndex].id} is rolling...";
    });

    Future.delayed(Duration(seconds: 1), () {
      int roll = random.nextInt(6) + 1;
      setState(() {
        diceRoll = roll;
        diceRolling = false;
        message = "${players[currentPlayerIndex].id} rolled a $roll!";
      });

      Future.delayed(Duration(milliseconds: 800), () {
        var mPawns = moveablePawns;
        if (mPawns.isEmpty) {
          setState(() {
            message = "No valid moves, moving to next player.";
          });
          Future.delayed(Duration(seconds: 2), () {
            canRollDice = true;
            nextTurn();
          });
        } else {
          setState(() {
            message = "Please tap a pawn to move.";
          });
        }
      });
    });
  }

  void aiPlayTurn() {
    if (gameOver) return;
    final currentPlayer = players[currentPlayerIndex];
    if (currentPlayer == null || !isAI(currentPlayer.id)) return;

    setState(() {
      message = "${currentPlayer.id} is thinking...";
    });

    Future.delayed(Duration(seconds: 2), () {
      aiRollDice();
    });
  }

  void aiRollDice() {
    if (gameOver) return;

    setState(() {
      diceRolling = true;
      diceRoll = null;
      message = "${players[currentPlayerIndex].id} is rolling...";
    });

    Future.delayed(Duration(seconds: 1), () {
      int roll = random.nextInt(6) + 1;
      setState(() {
        diceRoll = roll;
        diceRolling = false;
        message = "${players[currentPlayerIndex].id} rolled a $roll!";
      });

      Future.delayed(Duration(milliseconds: 1100), () {
        aiMakeMove();
      });
    });
  }

  void aiMakeMove() {
    if (gameOver) return;

    final mPawns = moveablePawns;
    if (mPawns.isEmpty) {
      setState(() {
        message = "${players[currentPlayerIndex].id} has no valid moves.";
      });
      Future.delayed(Duration(seconds: 2), () {
        nextTurn();
      });
      return;
    }

    final selectedPawn = mPawns[random.nextInt(mPawns.length)];
    setState(() {
      message = "${players[currentPlayerIndex].id} is moving...";
    });

    Future.delayed(Duration(seconds: 1), () {
      movePawn(selectedPawn);
    });
  }

  // MODIFIED: Remove the requirement for roll == 1 to enter board
  List<PawnState> get moveablePawns {
    if (diceRoll == null) return [];
    PlayerData player = players[currentPlayerIndex];
    
    return player.pawns.where((pawn) => canMovePawn(pawn, diceRoll!)).toList();
  }

  // MODIFIED: Allow any roll to enter board, not just roll == 1
  bool canMovePawn(PawnState pawn, int roll) {
    if (!pawnBelongsToCurrentPlayer(pawn)) return false;
    
    // If pawn is in base (position 0), allow any roll to enter
    if (pawn.position == 0) {
      return true; // CHANGED: was "return roll == Constants.startRoll;"
    } else {
      // If pawn is on board, check if move doesn't exceed winning square
      return (pawn.position + roll) <= Constants.winningSquare;
    }
  }

  bool pawnBelongsToCurrentPlayer(PawnState pawn) {
    return players[currentPlayerIndex].pawns.contains(pawn);
  }

  // MODIFIED: Add collision detection and hitting mechanics
  void movePawn(PawnState pawn) {
    if (diceRoll == null || gameOver) return;
    if (!canMovePawn(pawn, diceRoll!)) {
      setState(() {
        message = 'Invalid move.';
      });
      return;
    }

    int targetPosition;
    if (pawn.position == 0) {
      targetPosition = diceRoll!;
    } else {
      targetPosition = pawn.position + diceRoll!;
    }

    if (targetPosition > Constants.winningSquare) {
      targetPosition = Constants.winningSquare;
    }

    // ========== NEW: Check if this is a snake/ladder move (Feature 4) ==========
    isDirectAnimation = Constants.snacksAndLaddersMap.containsKey(targetPosition);

    checkAndHandleCollision(targetPosition);

    setState(() {
      selectedPawn = null;
      diceRoll = null;
      message = '${players[currentPlayerIndex].id} is moving...';
    });

    animatePawnMove(pawn, targetPosition);
  }

  // NEW: Handle collision detection and send opponent pawns back to base
  void checkAndHandleCollision(int targetPosition) {
    if (targetPosition == Constants.winningSquare || targetPosition == 0) return;

    String currentPlayerId = players[currentPlayerIndex].id;

    for (PlayerData player in players) {
      if (player.id == currentPlayerId) continue;

      for (PawnState pawn in player.pawns) {
        if (pawn.position == targetPosition) {
          setState(() {
            pawn.position = 0;
            pawn.displayPosition = 0;
          });

          // ========== NEW: Play hit opponent sound ==========
          audioManager.playHitOpponent();

          showEventDialog(
            context: context,
            title: '💥 Hit Opponent!',
            message: '${currentPlayerId} hit pawn of ${player.id} and sent back Home',
            icon: Icons.home_filled,
            titleColor: Colors.green,
            duration: const Duration(seconds: 5),
          );

          HapticFeedback.heavyImpact();
          return;
        }
      }
    }
  }

  void nextTurn() {
    setState(() {
      selectedPawn = null;
      diceRoll = null;
      diceRolling = false;
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    });

    int attempts = 0;
    while (players[currentPlayerIndex].pawns.every((pawn) => pawn.position == Constants.winningSquare) && 
           attempts < players.length) {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      attempts++;
    }

    final currentPlayer = players[currentPlayerIndex];
    
    if (currentPlayer.skipTurn) {
      message = "${currentPlayer.id}'s turn - but must skip due to hole!";
      if (!isAI(currentPlayer.id)) {
        showSkipTurnDialog();
      } else {
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            currentPlayer.skipTurn = false;
            message = "${currentPlayer.id} skipped turn due to hole!";
          });
          Future.delayed(Duration(seconds: 1), () {
            moveToNextPlayer();
          });
        });
      }
    } else {
      message = "${currentPlayer.id}'s turn.";
      if (isAI(currentPlayer.id)) {
        Future.delayed(Duration(seconds: 1), () => aiPlayTurn());
      }
    }
  }

  void showSkipTurnDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Skip Turn',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            'You are on a hole! You must skip this turn. Press OK to skip.',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  players[currentPlayerIndex].skipTurn = false;
                  message = "${players[currentPlayerIndex].id} skipped turn due to hole!";
                });
                Future.delayed(Duration(seconds: 1), () {
                  moveToNextPlayer();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void moveToNextPlayer() {
    setState(() {
      selectedPawn = null;
      diceRoll = null;
      diceRolling = false;
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    });

    int attempts = 0;
    while (players[currentPlayerIndex].pawns.every((pawn) => pawn.position == Constants.winningSquare) && 
           attempts < players.length) {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      attempts++;
    }

    final currentPlayer = players[currentPlayerIndex];
    
    if (currentPlayer.skipTurn) {
      message = "${currentPlayer.id}'s turn - but must skip due to hole!";
      if (!isAI(currentPlayer.id)) {
        showSkipTurnDialog();
      } else {
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            currentPlayer.skipTurn = false;
            message = "${currentPlayer.id} skipped turn due to hole!";
          });
          Future.delayed(Duration(seconds: 1), () {
            moveToNextPlayer();
          });
        });
      }
    } else {
      message = "${currentPlayer.id}'s turn.";
      if (isAI(currentPlayer.id)) {
        Future.delayed(Duration(seconds: 1), () => aiPlayTurn());
      }
    }
  }

  void showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Restart Game',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Are you sure you want to restart the game?',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showAdAndRestart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('Restart'),
            ),
          ],
        );
      },
    );
  }

  void showAdAndRestart() {
    AdManager.instance.showInterstitialAd(
      onAdClosed: () => startNewGame(),
    );
  }

  void returnToMainMenuWithAd() {
    // Show exit sound BEFORE leaving game
    audioManager.playGameExit();  // ✅ Play before navigating away

    // Then navigate
    if (!hasShownAdThisSession && diceRoll != null) {
      hasShownAdThisSession = true;
      AdManager.instance.showInterstitialAd(
        onAdClosed: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      );
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  Widget getPawnImage(String playerId, {double size = 20}) {
    final imagePath = pawnImages[playerId];
    final playerColor = getPlayerColor(playerId);

    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return buildPawnFallback(playerId, size, playerColor);
        },
      );
    }
    return buildPawnFallback(playerId, size, playerColor);
  }

  Widget buildPawnFallback(String playerId, double size, Color playerColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: playerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: playerColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          playerId[0],
          style: GoogleFonts.nunito(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color getPlayerColor(String playerId) {
    final index = widget.playerNames.indexOf(playerId);
    final colors = [Colors.blue[300]!, Colors.red[300]!, Colors.orange[300]!, Colors.green[300]!];
    return index >= 0 && index < colors.length ? colors[index] : Colors.grey;
  }

  Widget buildBoard() {
    List<Widget> squares = [];

    for (int i = 1; i <= 100; i++) {
      int row = 9 - ((i - 1) ~/ 10);
      bool isEvenRow = (row % 2) == 0;
      int col = isEvenRow ? (9 - ((i - 1) % 10)) : ((i - 1) % 10);

      List<PawnState> pawnsHere = [];
      for (var player in players) {
        pawnsHere.addAll(player.pawns.where((pawn) => 
          (pawn.displayPosition == i && !pawn.isAnimating) || 
          (pawn.isAnimating && pawn.displayPosition == i)));
      }

      List<Widget> pawnsWidgets = [];

      for (int index = 0; index < pawnsHere.length; index++) {
        PawnState pawn = pawnsHere[index];
        var player = players.firstWhere((p) => p.pawns.contains(pawn));

        int rowPos = index ~/ 2;
        int colPos = index % 2;
        double left = colPos * 16.0;
        double top = rowPos * 16.0;
        double pawnSize = pawnsHere.length <= 4 ? 16.0 : 20.0;

        bool isSelected = selectedPawn == pawn;

        pawnsWidgets.add(
          Positioned(
            left: left,
            top: top,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  HapticFeedback.selectionClick();

                  if (isAI(player.id)) return;
                  if (player.id != players[currentPlayerIndex].id) {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      message = "It's not your turn!";
                    });
                    return;
                  }

                  if (!canMovePawn(pawn, diceRoll ?? 0)) {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      message = 'Invalid pawn selection for current dice.';
                    });
                    return;
                  }

                  HapticFeedback.mediumImpact();
                  movePawn(pawn);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.identity()
                    ..scale(isSelected ? 1.25 : 1.0),
                  child: Container(
                    width: pawnSize + 12,
                    height: pawnSize + 12,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSelected)
                          Container(
                            width: pawnSize + 6,
                            height: pawnSize + 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.withOpacity(0.4),
                              border: Border.all(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                          ),
                        Container(
                          width: pawnSize,
                          height: pawnSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: getPlayerColor(player.id),
                            border: Border.all(color: Colors.white, width: 1),

                            // ========== Feature 1: Pawn glow/dim effect ==========
                            boxShadow: [
                              // GLOW for active player
                              if (players[currentPlayerIndex].id == player.id)
                                BoxShadow(
                                  color: getPlayerColor(player.id).withOpacity(0.8),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                )
                              // DIM for inactive players
                              else
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5,
                                )
                            ],
                          ),
                        ),
                        if (isAI(player.id))
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: const Color(0x0a424242),
                                //color: Colors.grey[800],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.smart_toy,
                                size: 8,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        if (getPawnImage(player.id, size: pawnSize) != null)
                          getPawnImage(player.id, size: pawnSize),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      squares.add(
        Positioned(
          left: col * 40.0,
          top: row * 40.0,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 1,
                  left: 2,
                  child: Text(
                    '$i',
                    style: GoogleFonts.nunito(
                      fontSize: 8,
                      color: const Color(0x8A116DA),
                      //color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSpecialSquare(i))
                  Positioned(
                    top: 1,
                    right: 2,
                    child: Icon(
                      getSquareIcon(i),
                      size: 8,
                      color: const Color(0x13D80841),
                    ),
                  ),
                ...pawnsWidgets,
              ],
            ),
          ),
        ),
      );
    }

    return Stack(children: squares);
  }

  Color getSquareColor(int position) {
    return Colors.transparent;
  }

  bool isSpecialSquare(int position) {
    return Constants.snacksAndLaddersMap.containsKey(position) ||
           Constants.bigHoleSquares.contains(position) ||
           Constants.goldMineSquares.contains(position) ||
           position == 100;
  }

  IconData getSquareIcon(int position) {
    if (position == 100) return Icons.home;
    if (Constants.snacksAndLaddersMap.containsKey(position)) {
      if (Constants.snacksAndLaddersMap[position]! > position) {
        return Icons.trending_up;
      } else {
        return Icons.trending_down;
      }
    }
    if (Constants.bigHoleSquares.contains(position)) return Icons.circle;
    if (Constants.goldMineSquares.contains(position)) return Icons.diamond;
    return Icons.help;
  }

  // MODIFIED: Updated base pawns display logic
  // MODIFIED: Updated base pawns display logic with OVERFLOW FIX
  Widget buildCompactPlayerInfo() {
    final currentPlayer = players[currentPlayerIndex];

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                getPawnImage(currentPlayer.id, size: 18),
                SizedBox(width: 6),
                Text(
                  currentPlayer.id,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
                if (isAI(currentPlayer.id))
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.smart_toy, size: 14, color: Colors.white70),
                  ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: SizedBox(),
          ),
          if (winnerId != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 14, color: Colors.black),
                  SizedBox(width: 4),
                  Text(
                    winnerId!,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  } 

  Widget buildAnimatedDice() {
    if (isAI(players[currentPlayerIndex].id)) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.grey[700]!, Colors.grey[600]!]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.smart_toy, color: Colors.purpleAccent, size: 24),
              SizedBox(height: 4),
              Text(
                'AI',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: canRollDice ? rollDice : null,
      child: AnimatedBuilder(
        animation: diceGlowAnimation,
        builder: (context, child) {
          // Calculate pulse intensity
          double glowIntensity = (diceShouldGlow && diceGlowAnimation.value != null)
              ? diceGlowAnimation.value
              : 0.0;

          // Create pulse effect: 0→1→0
          double pulseAmount = (glowIntensity < 0.5)
              ? glowIntensity * 2
              : (1 - glowIntensity) * 2;

          Color glowColor = diceShouldGlow ? Colors.amber : Colors.amberAccent[700]!;

          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: canRollDice
                  ? LinearGradient(colors: [Colors.amber, Colors.amberAccent])
                  : LinearGradient(colors: [Colors.red[700]!, Colors.redAccent[600]!]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // Glow shadow - pulses when ready
                BoxShadow(
                  color: glowColor.withOpacity(0.6 * pulseAmount),
                  blurRadius: 20 + (10 * pulseAmount), // 20-30 blur
                  spreadRadius: 2 + (5 * pulseAmount), // 2-7 spread
                  offset: Offset(0, 6),
                ),
                // Static shadow
                BoxShadow(
                  color: canRollDice
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.grey[700]!.withOpacity(0.4),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedDice(
              diceValue: diceRoll,
              rolling: diceRolling,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SNAKES & LADDERS',
          style: GoogleFonts.acme(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.pause, color: Colors.white),
          onPressed: () {
            setState(() {
              showPauseMenu = !showPauseMenu;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const GameRulesDialog(),
              );
            },
            tooltip: 'Game Rules',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: showResetConfirmation,
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple[900]!, Colors.grey[900]!],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Compact player info and dice in one row
                Container(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: buildCompactPlayerInfo()),
                      SizedBox(width: 16),
                      buildAnimatedDice(),
                    ],
                  ),
                ),

                // Message area
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 16),

                // Larger board area
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(42424290),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 400,
                            height: 400,
                            child: Stack(
                              children: [
                                Image.asset(
                                  'assets/board_bg.png',
                                  width: 400,
                                  height: 400,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 400,
                                      height: 400,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.brown[200]!, Colors.brown[400]!],
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Game Board',
                                          style: GoogleFonts.nunito(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown[800],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                buildBoard(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),
              ],
            ),

            // Special message overlay
            if (showSpecialMessage)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: 20,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.blueAccent],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      specialSquareMessage,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // Pause menu
            if (showPauseMenu)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(40),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Game Paused',
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24),
                        buildPauseButton('Resume', Icons.play_arrow, () {
                          setState(() {
                            showPauseMenu = false;
                          });
                        }),
                        SizedBox(height: 16),
                        buildPauseButton('Restart Game', Icons.refresh, () {
                          setState(() {
                            showPauseMenu = false;
                          });
                          showResetConfirmation();
                        }),
                        SizedBox(height: 16),
                        buildPauseButton('Main Menu', Icons.home, returnToMainMenuWithAd),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildPauseButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Keep your original AnimatedDice class exactly as is
class AnimatedDice extends StatefulWidget {
  final int? diceValue;
  final bool rolling;

  AnimatedDice({required this.diceValue, required this.rolling});

  @override
  _AnimatedDiceState createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> rotation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    rotation = Tween<double>(begin: 0, end: 1).animate(controller);

    if (widget.rolling) {
      controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling) {
      controller.repeat();
    } else {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String assetName = widget.diceValue != null
        ? 'assets/dice${widget.diceValue}.png'
        : 'assets/dice_idle.png';

    return RotationTransition(
      turns: rotation,
      child: Image.asset(
        assetName,
        width: 40,
        height: 40,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: widget.diceValue != null 
                  ? Text(
                      '${widget.diceValue}',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                  : Icon(Icons.casino, size: 24, color: Colors.grey[600]),
            ),
          );
        },
      ),
    );
  }
}