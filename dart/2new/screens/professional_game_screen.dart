
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../utils/constants.dart';
import '../models/enhanced_models.dart';
import '../widgets/custom_widgets.dart';

class ProfessionalGameScreen extends StatefulWidget {
  final List<String> playerNames;
  final int gameMode;

  const ProfessionalGameScreen({
    Key? key,
    required this.playerNames,
    required this.gameMode,
  }) : super(key: key);

  @override
  _ProfessionalGameScreenState createState() => _ProfessionalGameScreenState();
}

class _ProfessionalGameScreenState extends State<ProfessionalGameScreen> 
    with TickerProviderStateMixin {
  
  // Game state
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
  final List<String> _aiNames = ['AI Alpha', 'AI Beta', 'AI Gamma'];
  
  // Animation controllers
  late AnimationController _moveAnimationController;
  late AnimationController _diceAnimationController;
  late AnimationController _messageAnimationController;
  late Animation<double> _moveAnimation;
  late Animation<double> _diceRotation;
  late Animation<double> _messageAnimation;
  
  // Animation state
  int _animationStartPosition = 0;
  int _animationEndPosition = 0;
  PawnState? _animatingPawn;
  String _specialSquareMessage = '';
  bool _showSpecialMessage = false;
  Timer? _messageTimer;
  bool _canRollDice = true;
  bool _showPauseMenu = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePawnImages();
    _startNewGame();
  }

  @override
  void dispose() {
    _moveAnimationController.dispose();
    _diceAnimationController.dispose();
    _messageAnimationController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _moveAnimationController = AnimationController(
      vsync: this,
      duration: Constants.pawnMoveDuration,
    );
    
    _diceAnimationController = AnimationController(
      vsync: this,
      duration: Constants.diceRollDuration,
    );
    
    _messageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _moveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moveAnimationController, curve: Curves.easeInOut),
    );
    
    _diceRotation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _diceAnimationController, curve: Curves.easeInOut),
    );
    
    _messageAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _messageAnimationController, curve: Curves.easeInOut),
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

  bool _isAI(String playerId) => _aiNames.contains(playerId);

  void _startNewGame() {
    players = [];
    for (int i = 0; i < widget.playerNames.length; i++) {
      players.add(PlayerData(
        id: widget.playerNames[i],
        pawns: List.generate(
          Constants.pawnsPerPlayer,
          (index) => PawnState(index, 0),
        ),
        coins: 0, // Hidden but maintained for future features
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
      Future.delayed(Constants.aiThinkingDuration, () {
        _aiPlayTurn();
      });
    }
  }

  void _showMessage(String message, {Duration duration = Constants.messageDisplayDuration}) {
    setState(() {
      _specialSquareMessage = message;
      _showSpecialMessage = true;
    });
    _messageAnimationController.forward();
    
    _messageTimer?.cancel();
    _messageTimer = Timer(duration, () {
      _messageAnimationController.reverse().then((_) {
        setState(() {
          _showSpecialMessage = false;
        });
      });
    });
  }

  void _celebratePawnReaching100(PawnState pawn, PlayerData player) {
    HapticFeedback.lightImpact();
    _showMessage('🎉 ${player.id}\'s Pawn ${pawn.id + 1} reached home! 🎉',
        duration: const Duration(seconds: 3));
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

    // Check for snakes and ladders
    if (Constants.snacksAndLaddersMap.containsKey(pawn.position)) {
      int oldPos = pawn.position;
      int newPos = Constants.snacksAndLaddersMap[pawn.position]!;
      
      if (newPos > oldPos) {
        // Ladder
        currentPlayer.coins += Constants.ladderBonus; // Hidden coin system
        _showMessage('${currentPlayer.id} climbed a ladder from $oldPos to $newPos! 🪜');
        HapticFeedback.mediumImpact();
      } else {
        // Snake
        currentPlayer.coins += Constants.snackPenalty; // Hidden coin system
        if (currentPlayer.coins < 0) currentPlayer.coins = 0;
        _showMessage('${currentPlayer.id} slid down a snake from $oldPos to $newPos! 🐍');
        HapticFeedback.heavyImpact();
      }

      Future.delayed(const Duration(seconds: 1), () {
        _animatePawnMove(pawn, newPos);
      });
      return;
    }

    // Gold mines (hidden feature)
    if (Constants.goldMineSquares.contains(pawn.position)) {
      currentPlayer.coins += Constants.goldBonus;
      _showMessage('${currentPlayer.id} found a gold mine! ✨');
      HapticFeedback.lightImpact();
    }

    // Big holes
    if (Constants.bigHoleSquares.contains(pawn.position)) {
      currentPlayer.skipTurn = true;
      _showMessage('${currentPlayer.id} fell into a hole! Will skip next turn. 🕳️');
      HapticFeedback.heavyImpact();
      
      _checkForWinner();
      if (!gameOver) {
        Future.delayed(const Duration(seconds: 2), () {
          nextTurn();
        });
      }
      return;
    }

    _checkForWinner();
    if (!gameOver) {
      Future.delayed(const Duration(seconds: 2), () {
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
      _showMessage('${currentPlayer.id} has finished all pawns! 🏆', duration: const Duration(seconds: 3));
    }

    bool allPlayersFinished = players.every((player) =>
        player.pawns.every((pawn) => pawn.position == Constants.winningSquare));
        
    if (allPlayersFinished) {
      setState(() {
        gameOver = true;
      });
      _showMessage('Game Over! ${winnerId ?? "No one"} wins! 🎉', duration: const Duration(seconds: 5));
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

    _diceAnimationController.forward().then((_) {
      _diceAnimationController.reset();
    });

    Future.delayed(const Duration(seconds: 1), () {
      int roll = _random.nextInt(6) + 1;
      setState(() {
        diceRoll = roll;
        diceRolling = false;
        message = '${players[currentPlayerIndex].id} rolled a $roll';
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        var mPawns = moveablePawns();
        if (mPawns.isEmpty) {
          setState(() {
            message = "No valid moves; moving to next player.";
          });
          Future.delayed(const Duration(seconds: 2), () {
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
    
    Future.delayed(const Duration(seconds: 2), () {
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

    _diceAnimationController.forward().then((_) {
      _diceAnimationController.reset();
    });

    Future.delayed(const Duration(seconds: 1), () {
      int roll = _random.nextInt(6) + 1;
      setState(() {
        diceRoll = roll;
        diceRolling = false;
        message = '${players[currentPlayerIndex].id} rolled a $roll';
      });

      Future.delayed(const Duration(milliseconds: 1100), () {
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
      Future.delayed(const Duration(seconds: 2), nextTurn);
      return;
    }

    final selectedPawn = mPawns[_random.nextInt(mPawns.length)];
    setState(() {
      message = '${players[currentPlayerIndex].id} is moving...';
    });
    
    Future.delayed(const Duration(seconds: 1), () {
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
          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              currentPlayer.skipTurn = false;
              message = '${currentPlayer.id} skipped turn due to hole!';
            });
            
            Future.delayed(const Duration(seconds: 1), () {
              nextTurn();
            });
          });
        }
      } else {
        message = '${currentPlayer.id}\'s turn.';
        
        if (_isAI(currentPlayer.id)) {
          Future.delayed(const Duration(seconds: 1), () {
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
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Skip Turn',
            style: AppStyles.heading3,
          ),
          content: Text(
            'You are on a hole! You must skip this turn. Press OK to skip.',
            style: AppStyles.bodyMedium,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  players[currentPlayerIndex].skipTurn = false;
                  message = '${players[currentPlayerIndex].id} skipped turn due to hole!';
                });
                
                Future.delayed(const Duration(seconds: 1), () {
                  nextTurn();
                });
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildPlayersInfoRow(),
                const SizedBox(height: 16),
                _buildGameMessage(),
                const SizedBox(height: 16),
                _buildDiceArea(),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildGameBoard(),
                ),
                const SizedBox(height: 16),
                _buildBasePawnsArea(),
                const SizedBox(height: 16),
              ],
            ),
            if (_showSpecialMessage) _buildSpecialMessage(),
            if (_showPauseMenu) _buildPauseMenu(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
      ),
      title: Text(
        'SNAKES & LADDERS',
        style: AppStyles.heading3.copyWith(color: Colors.white),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.pause, color: Colors.white),
        onPressed: () => setState(() => _showPauseMenu = true),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _showRestartDialog,
        ),
      ],
    );
  }

  Widget _buildPlayersInfoRow() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          final isCurrent = index == currentPlayerIndex;
          final finishedCount = player.pawns.where((pawn) => pawn.position == Constants.winningSquare).length;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 150,
            decoration: BoxDecoration(
              gradient: isCurrent ? AppColors.primaryGradient : AppColors.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCurrent ? AppColors.primary : Colors.black).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _truncateText(player.id, 12),
                          style: AppStyles.bodyLarge.copyWith(
                            color: isCurrent ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isAI(player.id))
                        Icon(
                          Icons.smart_toy,
                          size: 16,
                          color: isCurrent ? Colors.white70 : AppColors.primaryLight,
                        ),
                      if (winnerId == player.id)
                        Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.amber,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 16,
                        color: isCurrent ? Colors.white70 : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$finishedCount/4',
                        style: AppStyles.bodySmall.copyWith(
                          color: isCurrent ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: player.pawns.map((pawn) {
                      bool isOnBoard = pawn.position != 0;
                      bool isFinished = pawn.position == Constants.winningSquare;
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 4),
                        child: Stack(
                          children: [
                            _getPawnWidget(player.id, size: 16),
                            if (isFinished)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
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

  Widget _buildGameMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Text(
        message,
        style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDiceArea() {
    if (_isAI(players[currentPlayerIndex].id)) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.smart_toy,
                color: AppColors.primaryLight,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'AI Turn',
                style: AppStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _canRollDice ? _rollDice : null,
      child: AnimatedBuilder(
        animation: _diceRotation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _diceRotation.value * 2 * 3.14159,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: _canRollDice ? AppColors.primaryGradient : AppColors.cardGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_canRollDice ? AppColors.primary : Colors.black).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: diceRoll != null
                    ? Text(
                        diceRoll.toString(),
                        style: AppStyles.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Icon(
                        Icons.casino,
                        size: 32,
                        color: Colors.white,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameBoard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: _buildBoardGrid(),
          ),
        ),
      ),
    );
  }

  Widget _buildBoardGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        childAspectRatio: 1.0,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 100,
      itemBuilder: (context, index) {
        int position = 100 - index;
        int row = index ~/ 10;
        bool isEvenRow = row % 2 == 0;
        
        if (!isEvenRow) {
          int colFromRight = index % 10;
          position = 100 - (row * 10) - colFromRight;
        }
        
        return _buildBoardSquare(position);
      },
    );
  }

  Widget _buildBoardSquare(int position) {
    List<PawnState> pawnsHere = [];
    for (var player in players) {
      pawnsHere.addAll(player.pawns.where((pawn) =>
          pawn.displayPosition == position ||
          (pawn.isAnimating && pawn.displayPosition == position)));
    }

    Color squareColor = _getSquareColor(position);
    bool isSpecial = Constants.isSpecialSquare(position);

    return Container(
      decoration: BoxDecoration(
        color: squareColor,
        border: Border.all(
          color: isSpecial ? Colors.white : Colors.white24,
          width: isSpecial ? 1.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Position number
          Positioned(
            top: 1,
            left: 2,
            child: Text(
              position.toString(),
              style: TextStyle(
                fontSize: 8,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Special square indicator
          if (isSpecial)
            Positioned(
              top: 1,
              right: 2,
              child: Icon(
                _getSquareIcon(position),
                size: 8,
                color: Colors.white,
              ),
            ),
          
          // Pawns
          ...pawnsHere.asMap().entries.map((entry) {
            int pawnIndex = entry.key;
            PawnState pawn = entry.value;
            var player = players.firstWhere((p) => p.pawns.contains(pawn));
            
            double left = (pawnIndex % 2) * 12.0;
            double top = (pawnIndex ~/ 2) * 12.0;
            
            return Positioned(
              left: left,
              top: top + 12,
              child: GestureDetector(
                onTap: () {
                  if (_isAI(player.id) || player.id != players[currentPlayerIndex].id) return;
                  if (!canMovePawn(pawn, diceRoll ?? 0)) return;
                  movePawn(pawn);
                },
                child: _getPawnWidget(player.id, size: 12),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getSquareColor(int position) {
    if (position == 100) return AppColors.success.withOpacity(0.8);
    if (Constants.isLadder(position)) return AppColors.ladder.withOpacity(0.6);
    if (Constants.isSnake(position)) return AppColors.snake.withOpacity(0.6);
    if (Constants.bigHoleSquares.contains(position)) return AppColors.hole.withOpacity(0.6);
    if (Constants.goldMineSquares.contains(position)) return AppColors.goldMine.withOpacity(0.6);
    
    return AppColors.surface.withOpacity(0.8);
  }

  IconData _getSquareIcon(int position) {
    if (Constants.isLadder(position)) return Icons.trending_up;
    if (Constants.isSnake(position)) return Icons.trending_down;
    if (Constants.bigHoleSquares.contains(position)) return Icons.circle;
    if (Constants.goldMineSquares.contains(position)) return Icons.diamond;
    return Icons.help;
  }

  Widget _getPawnWidget(String playerId, {double size = 20}) {
    Color playerColor = _getPlayerColor(playerId);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: playerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
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
          style: TextStyle(
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
    final colors = [AppColors.player1, AppColors.player2, AppColors.player3, AppColors.player4];
    return index >= 0 && index < colors.length ? colors[index] : Colors.grey;
  }

  Widget _buildBasePawnsArea() {
    final player = players[currentPlayerIndex];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${player.id}\'s Base',
                style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_isAI(player.id)) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: player.pawns.asMap().entries.map((entry) {
              int idx = entry.key;
              PawnState pawn = entry.value;
              bool isInBase = pawn.position == 0;
              bool canMove = diceRoll == Constants.startRoll && isInBase;
              
              return GestureDetector(
                onTap: () {
                  if (_isAI(player.id) || !canMove) return;
                  movePawn(pawn);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: canMove && !_isAI(player.id) ? AppColors.primaryGradient : null,
                    color: canMove && !_isAI(player.id) ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canMove ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: isInBase ? 1.0 : 0.4,
                        child: _getPawnWidget(player.id, size: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'P${idx + 1}',
                        style: AppStyles.bodySmall.copyWith(
                          color: canMove ? Colors.white : AppColors.textMuted,
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

  Widget _buildSpecialMessage() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _messageAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _messageAnimation.value,
            child: Opacity(
              opacity: _messageAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  _specialSquareMessage,
                  style: AppStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPauseMenu() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(24),
          decoration: AppStyles.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game Paused',
                style: AppStyles.heading2,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Resume',
                onPressed: () => setState(() => _showPauseMenu = false),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Restart Game',
                onPressed: _showRestartDialog,
                isSecondary: true,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Main Menu',
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                isSecondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Restart Game', style: AppStyles.heading3),
        content: Text(
          'Are you sure you want to restart the game? All progress will be lost.',
          style: AppStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppStyles.buttonMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showPauseMenu = false);
              _startNewGame();
            },
            child: Text('Restart'),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
