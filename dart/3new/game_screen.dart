
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'models.dart';

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
  String message = '';
  bool gameOver = false;
  String? winnerId;
  PawnState? selectedPawn;
  late Map<String, String> pawnImages;
  final Random _random = Random();
  final List<String> _aiNames = ['CobraBot', 'Laddie', 'DiceMaster'];
  late AnimationController _jumpAnimationController;
  late Animation<double> _jumpAnimation;
  bool _canRollDice = true;
  bool _showPauseMenu = false;

  // Animation properties
  late AnimationController _moveAnimationController;
  late Animation<double> _moveAnimation;
  int _animationStartPosition = 0;
  int _animationEndPosition = 0;
  PawnState? _animatingPawn;
  String _specialSquareMessage = '';
  bool _showSpecialMessage = false;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _initializePawnImages();
    _initializeAnimations();
    _startNewGame();
  }

  @override
  void dispose() {
    _moveAnimationController.dispose();
    _jumpAnimationController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    // Initialize animation controller
    _moveAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _moveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _moveAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _jumpAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _jumpAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _jumpAnimationController,
        curve: Curves.bounceOut,
      ),
    );

    _moveAnimationController.addListener(() {
      setState(() {
        if (_animatingPawn != null) {
          _animatingPawn!.displayPosition = _animationStartPosition +
              ((_animationEndPosition - _animationStartPosition) * _moveAnimation.value).round();
        }
      });
    });

    _moveAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeMoveAnimation();
      }
    });
  }

  void _initializePawnImages() {
    pawnImages = {};
    final colors = ['blue', 'red', 'yellow', 'green'];
    for (int i = 0; i < widget.playerNames.length; i++) {
      if (i < colors.length) {
        pawnImages[widget.playerNames[i]] = 'assets/pawn_${colors[i]}.png';
      } else {
        pawnImages[widget.playerNames[i]] = 'assets/pawn_blue.png';
      }
    }
  }

  bool _isAI(String playerId) {
    return _aiNames.contains(playerId);
  }

  void _startNewGame() {
    players = [];
    for (int i = 0; i < widget.playerNames.length; i++) {
      players.add(PlayerData(
        id: widget.playerNames[i],
        pawns: List.generate(
          Constants.pawnsPerPlayer,
          (index) => PawnState(index, 0),
        ),
        coins: 0, // Keep coins in code but hidden from UI
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
    message = '${players[currentPlayerIndex].id}\'s turn';
    
    if (_isAI(players[currentPlayerIndex].id)) {
      Future.delayed(Duration(seconds: 1), () {
        _aiPlayTurn();
      });
    }
  }

  void _showMessage(String message, {Duration duration = const Duration(seconds: 2)}) {
    HapticFeedback.lightImpact();
    setState(() {
      _specialSquareMessage = message;
      _showSpecialMessage = true;
    });
    _messageTimer?.cancel();
    _messageTimer = Timer(duration, () {
      setState(() {
        _showSpecialMessage = false;
      });
    });
  }

  void _celebratePawnReaching100(PawnState pawn, PlayerData player) {
    HapticFeedback.heavyImpact();
    _showMessage('🎉 ${player.id}\'s Pawn ${pawn.id + 1} reached home! 🎉',
        duration: Duration(seconds: 3));
  }

  void _animatePawnMove(PawnState pawn, int targetPosition) {
    setState(() {
      _animatingPawn = pawn;
      _animationStartPosition = pawn.displayPosition;
      _animationEndPosition = targetPosition;
      pawn.isAnimating = true;
      _moveAnimationController.reset();
      _moveAnimationController.forward();
    });
  }

  void _completeMoveAnimation() {
    if (_animatingPawn != null) {
      setState(() {
        _animatingPawn!.position = _animationEndPosition;
        _animatingPawn!.displayPosition = _animationEndPosition;
        _animatingPawn!.isAnimating = false;
      });
      
      final currentPlayer = players[currentPlayerIndex];
      if (_animationEndPosition == Constants.winningSquare) {
        _celebratePawnReaching100(_animatingPawn!, currentPlayer);
      }

      _checkSpecialSquares();

      setState(() {
        _canRollDice = true;
      });
    }
  }

  void _checkSpecialSquares() {
    final currentPlayer = players[currentPlayerIndex];
    final pawn = currentPlayer.pawns.firstWhere((p) => p.position == _animationEndPosition);
    
    if (_animationEndPosition == Constants.winningSquare) {
      _celebratePawnReaching100(pawn, currentPlayer);
      return;
    }

    // Check for snakes and ladders FIRST
    if (Constants.snacksAndLaddersMap.containsKey(pawn.position)) {
      int oldPos = pawn.position;
      int newPos = Constants.snacksAndLaddersMap[pawn.position]!;
      if (newPos > oldPos) {
        // Ladder - add bonus coins (hidden)
        currentPlayer.coins += Constants.ladderBonus;
        _showMessage('${currentPlayer.id} climbed a ladder from $oldPos to $newPos! 🪜');
        HapticFeedback.mediumImpact();
      } else {
        // Snake - apply penalty (hidden)
        currentPlayer.coins += Constants.snackPenalty;
        if (currentPlayer.coins < 0) currentPlayer.coins = 0;
        _showMessage('${currentPlayer.id} got bitten by a snake from $oldPos to $newPos! 🐍');
        HapticFeedback.heavyImpact();
      }

      Future.delayed(Duration(seconds: 1), () {
        _animatePawnMove(pawn, newPos);
      });
      return;
    }

    // Only check these if NOT on a snake/ladder square
    if (Constants.goldMineSquares.contains(pawn.position)) {
      currentPlayer.coins += Constants.goldBonus; // Hidden coin system
      _showMessage('${currentPlayer.id} found a gold mine! ✨');
      HapticFeedback.lightImpact();
    }

    // Handle big hole squares
    if (Constants.bigHoleSquares.contains(pawn.position)) {
      currentPlayer.skipTurn = true;
      _showMessage('${currentPlayer.id} fell into a hole! Will skip next turn. 🕳️');
      HapticFeedback.heavyImpact();
      
      _checkForWinner();
      if (!gameOver) {
        Future.delayed(Duration(seconds: 2), () {
          nextTurn();
        });
      }
      return;
    }

    _checkForWinner();
    if (!gameOver) {
      Future.delayed(Duration(seconds: 2), () {
        nextTurn();
      });
    }
  }

  void _checkForWinner() {
    final currentPlayer = players[currentPlayerIndex];
    bool allPawnsFinished = currentPlayer.pawns.every((pawn) => pawn.position == Constants.winningSquare);
    
    if (allPawnsFinished && winnerId == null) {
      setState(() {
        winnerId = currentPlayer.id;
        gameOver = false;
      });
      _showMessage('${currentPlayer.id} has finished all pawns! 🏆', duration: Duration(seconds: 3));
    }

    bool allPlayersFinished = players.every((player) =>
        player.pawns.every((pawn) => pawn.position == Constants.winningSquare));
        
    if (allPlayersFinished) {
      setState(() {
        gameOver = true;
      });
      _showMessage('Game Over! ${winnerId ?? "No one"} wins! 🎉', duration: Duration(seconds: 5));
    }
  }

  void _rollDice() {
    if (diceRolling || gameOver || !_canRollDice) return;
    if (_isAI(players[currentPlayerIndex].id)) return;
    if (diceRoll != null && moveablePawns().isNotEmpty) {
      setState(() {
        message = 'Please move a valid pawn before rolling again.';
      });
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      diceRolling = true;
      _canRollDice = false;
      diceRoll = null;
      message = '${players[currentPlayerIndex].id} is rolling...';
    });
    
    Future.delayed(Duration(seconds: 1), () {
      int roll = _random.nextInt(6) + 1;
      setState(() {
        diceRoll = roll;
        diceRolling = false;
        message = '${players[currentPlayerIndex].id} rolled a $roll';
      });
      
      Future.delayed(Duration(milliseconds: 800), () {
        var mPawns = moveablePawns();
        if (mPawns.isEmpty) {
          setState(() {
            message = "No valid moves; moving to next player.";
          });
          Future.delayed(Duration(seconds: 2), () {
            _canRollDice = true;
            nextTurn();
          });
        } else {
          setState(() {
            message = 'Please tap a pawn to move.';
          });
        }
      });
    });
  }

  void _aiPlayTurn() {
    if (gameOver) return;
    final currentPlayer = players[currentPlayerIndex];
    if (currentPlayer == null || !_isAI(currentPlayer.id)) return;
    
    setState(() {
      message = '${currentPlayer.id} is thinking...';
    });
    
    Future.delayed(Duration(seconds: 2), () {
      _aiRollDice();
    });
  }

  void _aiRollDice() {
    if (gameOver) return;
    setState(() {
      diceRolling = true;
      diceRoll = null;
      message = '${players[currentPlayerIndex].id} is rolling...';
    });
    
    Future.delayed(Duration(seconds: 1), () {
      int roll = _random.nextInt(6) + 1;
      setState(() {
        diceRoll = roll;
        diceRolling = false;
        message = '${players[currentPlayerIndex].id} rolled a $roll';
      });
      
      Future.delayed(Duration(milliseconds: 1100), () {
        _aiMakeMove();
      });
    });
  }

  void _aiMakeMove() {
    if (gameOver) return;
    final mPawns = moveablePawns();
    if (mPawns.isEmpty) {
      setState(() {
        message = "${players[currentPlayerIndex].id} has no valid moves.";
      });
      Future.delayed(Duration(seconds: 2), nextTurn);
      return;
    }

    final selectedPawn = mPawns[_random.nextInt(mPawns.length)];
    setState(() {
      message = '${players[currentPlayerIndex].id} is moving...';
    });
    
    Future.delayed(Duration(seconds: 1), () {
      movePawn(selectedPawn);
    });
  }

  List<PawnState> moveablePawns() {
    if (diceRoll == null) return [];
    PlayerData player = players[currentPlayerIndex];
    return player.pawns.where((pawn) => canMovePawn(pawn, diceRoll!)).toList();
  }

  bool canMovePawn(PawnState pawn, int roll) {
    if (pawnBelongsToCurrentPlayer(pawn)) {
      if (pawn.position == 0) {
        return roll == Constants.startRoll;
      } else {
        return (pawn.position + roll) <= Constants.winningSquare;
      }
    }
    return false;
  }

  bool pawnBelongsToCurrentPlayer(PawnState pawn) {
    return players[currentPlayerIndex].pawns.contains(pawn);
  }

  void movePawn(PawnState pawn) {
    if (diceRoll == null || gameOver) return;
    if (!canMovePawn(pawn, diceRoll!)) {
      setState(() {
        message = 'Invalid move. Please select a valid pawn.';
      });
      return;
    }

    int targetPosition;
    if (pawn.position == 0) {
      targetPosition = 1;
    } else {
      targetPosition = pawn.position + diceRoll!;
      if (targetPosition > Constants.winningSquare) {
        targetPosition = Constants.winningSquare;
      }
    }

    setState(() {
      selectedPawn = null;
      diceRoll = null;
      message = '${players[currentPlayerIndex].id} is moving...';
    });
    
    _animatePawnMove(pawn, targetPosition);
  }

  void nextTurn() {
    setState(() {
      selectedPawn = null;
      diceRoll = null;
      diceRolling = false;
      
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      
      int attempts = 0;
      while (players[currentPlayerIndex].pawns.every((pawn) => pawn.position == Constants.winningSquare) &&
             attempts < players.length) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
        attempts++;
      }

      final currentPlayer = players[currentPlayerIndex];
      
      if (currentPlayer.skipTurn) {
        message = '${currentPlayer.id}\'s turn - but must skip due to hole!';
        if (!_isAI(currentPlayer.id)) {
          _showSkipTurnDialog();
        } else {
          Future.delayed(Duration(seconds: 2), () {
            setState(() {
              currentPlayer.skipTurn = false;
              message = '${currentPlayer.id} skipped turn due to hole!';
            });
            Future.delayed(Duration(seconds: 1), () {
              _moveToNextPlayer();
            });
          });
        }
      } else {
        message = '${currentPlayer.id}\'s turn.';
        if (_isAI(currentPlayer.id)) {
          Future.delayed(Duration(seconds: 1), () {
            _aiPlayTurn();
          });
        }
      }
    });
  }

  void _showSkipTurnDialog() {
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
                  message = '${players[currentPlayerIndex].id} skipped turn due to hole!';
                });
                Future.delayed(Duration(seconds: 1), () {
                  _moveToNextPlayer();
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

  void _moveToNextPlayer() {
    setState(() {
      selectedPawn = null;
      diceRoll = null;
      diceRolling = false;
      
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      
      int attempts = 0;
      while (players[currentPlayerIndex].pawns.every((pawn) => pawn.position == Constants.winningSquare) &&
             attempts < players.length) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
        attempts++;
      }

      final currentPlayer = players[currentPlayerIndex];
      
      if (currentPlayer.skipTurn) {
        message = '${currentPlayer.id}\'s turn - but must skip due to hole!';
        if (!_isAI(currentPlayer.id)) {
          _showSkipTurnDialog();
        } else {
          Future.delayed(Duration(seconds: 2), () {
            setState(() {
              currentPlayer.skipTurn = false;
              message = '${currentPlayer.id} skipped turn due to hole!';
            });
            Future.delayed(Duration(seconds: 1), () {
              _moveToNextPlayer();
            });
          });
        }
      } else {
        message = '${currentPlayer.id}\'s turn.';
        if (_isAI(currentPlayer.id)) {
          Future.delayed(Duration(seconds: 1), () {
            _aiPlayTurn();
          });
        }
      }
    });
  }

  void _showResetConfirmation() {
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
                _startNewGame();
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

  Widget _getPawnImage(String playerId, {double size = 20}) {
    final imagePath = pawnImages[playerId];
    final playerColor = _getPlayerColor(playerId);
    
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPawnFallback(playerId, size, playerColor);
        },
      );
    }

    return _buildPawnFallback(playerId, size, playerColor);
  }

  Widget _buildPawnFallback(String playerId, double size, Color playerColor) {
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

  Color _getPlayerColor(String playerId) {
    final index = widget.playerNames.indexOf(playerId);
    final colors = [
      Colors.blue[600]!,
      Colors.red[600]!,
      Colors.orange[600]!,
      Colors.green[600]!,
    ];
    return index >= 0 && index < colors.length ? colors[index] : Colors.grey;
  }

  // Keep your exact board building logic
  Widget buildBoard() {
    List<Widget> squares = [];
    for (int i = 1; i <= 100; i++) {
      int row = 9 - ((i - 1) ~/ 10); // Row from bottom (0) to top (9)
      bool isEvenRow = (row % 2 == 0);
      int col = isEvenRow ? 9 - ((i - 1) % 10) : (i - 1) % 10; // Your original logic

      List<PawnState> pawnsHere = [];
      for (var player in players) {
        pawnsHere.addAll(player.pawns.where((pawn) =>
            pawn.displayPosition == i ||
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
        double pawnSize = pawnsHere.length > 4 ? 16.0 : 20.0;

        pawnsWidgets.add(
          Positioned(
            left: left,
            top: top,
            child: GestureDetector(
              onTap: () {
                if (_isAI(player.id)) return;
                if (player.id != players[currentPlayerIndex].id) {
                  setState(() {
                    message = "It's not your turn!";
                  });
                  return;
                }

                if (!canMovePawn(pawn, diceRoll ?? 0)) {
                  setState(() {
                    message = 'Invalid pawn selection for current dice.';
                  });
                  return;
                }

                movePawn(pawn);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _getPawnImage(player.id, size: pawnSize),
                  if (_isAI(player.id))
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.smart_toy,
                          size: 8,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  if (pawn == selectedPawn)
                    Container(
                      width: pawnSize + 4,
                      height: pawnSize + 4,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }

      // Color coding for special squares
      Color squareColor = _getSquareColor(i);

      squares.add(Positioned(
        left: col * 40.0,
        top: row * 40.0,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 0.5),
            color: squareColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 1,
                left: 2,
                child: Text(
                  "$i",
                  style: GoogleFonts.nunito(
                    fontSize: 8,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Special square indicators
              if (_isSpecialSquare(i))
                Positioned(
                  top: 1,
                  right: 2,
                  child: Icon(
                    _getSquareIcon(i),
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ...pawnsWidgets,
            ],
          ),
        ),
      ));
    }

    return Stack(children: squares);
  }

  Color _getSquareColor(int position) {
    if (position == 100) return Colors.green.withOpacity(0.8); // Home
    if (Constants.snacksAndLaddersMap.containsKey(position)) {
      if (Constants.snacksAndLaddersMap[position]! > position) {
        return Colors.green.withOpacity(0.6); // Ladder
      } else {
        return Colors.red.withOpacity(0.6); // Snake
      }
    }
    if (Constants.bigHoleSquares.contains(position)) {
      return Colors.brown.withOpacity(0.6); // Hole
    }
    if (Constants.goldMineSquares.contains(position)) {
      return Colors.yellow.withOpacity(0.6); // Gold mine
    }
    return Colors.grey[700]!.withOpacity(0.3); // Regular square
  }

  bool _isSpecialSquare(int position) {
    return Constants.snacksAndLaddersMap.containsKey(position) ||
           Constants.bigHoleSquares.contains(position) ||
           Constants.goldMineSquares.contains(position) ||
           position == 100;
  }

  IconData _getSquareIcon(int position) {
    if (position == 100) return Icons.home;
    if (Constants.snacksAndLaddersMap.containsKey(position)) {
      if (Constants.snacksAndLaddersMap[position]! > position) {
        return Icons.trending_up; // Ladder
      } else {
        return Icons.trending_down; // Snake
      }
    }
    if (Constants.bigHoleSquares.contains(position)) {
      return Icons.circle; // Hole
    }
    if (Constants.goldMineSquares.contains(position)) {
      return Icons.diamond; // Gold mine
    }
    return Icons.help;
  }

  Widget buildBasePawnsArea() {
    final player = players[currentPlayerIndex];
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${player.id}\'s Base',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              if (_isAI(player.id)) ...[
                SizedBox(width: 8),
                Icon(Icons.smart_toy, size: 16, color: Colors.blueAccent),
              ],
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: player.pawns.asMap().entries.map((entry) {
              int idx = entry.key;
              PawnState pawn = entry.value;
              bool isInBase = pawn.position == 0;
              bool canMove = diceRoll == Constants.startRoll && isInBase;

              return GestureDetector(
                onTap: () {
                  if (_isAI(player.id)) return;
                  if (!canMove) {
                    setState(() {
                      message = 'Invalid pawn selection for current dice.';
                    });
                    return;
                  }
                  movePawn(pawn);
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: canMove && !_isAI(player.id) 
                        ? LinearGradient(colors: [Colors.green, Colors.green[400]!])
                        : null,
                    color: canMove && !_isAI(player.id) ? null : Colors.grey[700],
                    borderRadius: BorderRadius.circular(12),
                    border: canMove ? Border.all(color: Colors.green, width: 2) : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: isInBase ? 1.0 : 0.4,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _getPawnImage(player.id, size: 28),
                            if (canMove && !_isAI(player.id))
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            if (_isAI(player.id))
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.smart_toy,
                                    size: 10,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pawn ${idx + 1}',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: canMove ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildPlayersInfoRow() {
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          final isCurrent = index == currentPlayerIndex;
          final finishedCount = player.pawns.where((pawn) => pawn.position == Constants.winningSquare).length;
          
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 6),
            width: 140,
            decoration: BoxDecoration(
              gradient: isCurrent 
                  ? LinearGradient(colors: [Colors.blue, Colors.blueAccent])
                  : LinearGradient(colors: [Colors.grey[800]!, Colors.grey[700]!]),
              borderRadius: BorderRadius.circular(16),
              border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: (isCurrent ? Colors.blueGrey : Colors.black54).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _truncateText(player.id, 10),
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isAI(player.id))
                        Icon(Icons.smart_toy, size: 12, color: Colors.white70),
                      if (winnerId == player.id)
                        Icon(Icons.emoji_events, size: 12, color: Colors.amber),
                    ],
                  ),
                  SizedBox(height: 6),
                  // Remove coin display, keep only progress
                  Row(
                    children: [
                      Icon(Icons.flag, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '$finishedCount/4',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: player.pawns.map((pawn) {
                      bool isFinished = pawn.position == Constants.winningSquare;
                      return Container(
                        margin: EdgeInsets.only(right: 4),
                        child: Stack(
                          children: [
                            _getPawnImage(player.id, size: 14),
                            if (isFinished)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  }

  Widget buildAnimatedDice() {
    if (_isAI(players[currentPlayerIndex].id)) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[700]!, Colors.grey[600]!],
          ),
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
              Icon(
                Icons.smart_toy,
                color: Colors.purpleAccent,
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                'AI\nTurn',
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
      onTap: _canRollDice ? _rollDice : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: _canRollDice 
              ? LinearGradient(colors: [Colors.blue, Colors.blueAccent])
              : LinearGradient(colors: [Colors.grey[700]!, Colors.grey[600]!]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_canRollDice ? Colors.blue : Colors.grey[700]!).withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: AnimatedDice(
            diceValue: diceRoll,
            rolling: diceRolling,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SNAKES & LADDERS',
          style: GoogleFonts.pressStart2p(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.pause, color: Colors.white),
          onPressed: () => setState(() => _showPauseMenu = !_showPauseMenu),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _showResetConfirmation,
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
                buildPlayersInfoRow(),
                SizedBox(height: 12),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(16),
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
                buildAnimatedDice(),
                SizedBox(height: 16),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: Container(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 400,
                            height: 400,
                            child: Stack(
                              children: [
                                // Board background with fallback
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
                               Opacity(
                                  opacity: 0.05, // <-- 5% visible, adjust as needed
                                  child: buildBoard(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                buildBasePawnsArea(),
                SizedBox(height: 16),
              ],
            ),
            
            // Special message overlay
            if (_showSpecialMessage)
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
                      _specialSquareMessage,
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
            if (_showPauseMenu)
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
                        _buildPauseButton('Resume', Icons.play_arrow, () {
                          setState(() => _showPauseMenu = false);
                        }),
                        SizedBox(height: 16),
                        _buildPauseButton('Restart Game', Icons.refresh, () {
                          setState(() => _showPauseMenu = false);
                          _showResetConfirmation();
                        }),
                        SizedBox(height: 16),
                        _buildPauseButton('Main Menu', Icons.home, () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }),
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

  Widget _buildPauseButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
        ),
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
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _rotation = Tween<double>(begin: 0, end: 1).animate(_controller);
    if (widget.rolling) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String assetName = widget.diceValue != null
        ? 'assets/dice_${widget.diceValue}.png'
        : 'assets/dice_idle.png';
        
    return RotationTransition(
      turns: _rotation,
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
