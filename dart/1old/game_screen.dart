import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snacks_ladders/main.dart';
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

  // Animation properties
  late AnimationController _moveAnimationController;
  late Animation<double> _moveAnimation;
  int _animationStartPosition = 0;
  int _animationEndPosition = 0;
  PawnState? _animatingPawn;
  String _specialSquareMessage = '';
  bool _showSpecialMessage = false;
  Timer? _messageTimer;
  bool _showResetDialog = false;

  @override
  void initState() {
    super.initState();
    _initializePawnImages();

    // Initialize animation controller
    _moveAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _moveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _moveAnimationController,
        curve: Curves.easeInOut,
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

    _startNewGame();
  }

  @override
  void dispose() {
    _moveAnimationController.dispose();
    _messageTimer?.cancel();
    super.dispose();
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
                (index) => PawnState(index, 0)
        ),
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
    message = '${players[currentPlayerIndex].id}\'s turn';

    if (_isAI(players[currentPlayerIndex].id)) {
      Future.delayed(Duration(seconds: 1), () {
        _aiPlayTurn();
      });
    }
  }

  void _showMessage(String message, {Duration duration = const Duration(seconds: 2)}) {
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

      // Check if pawn reached 100
      final currentPlayer = players[currentPlayerIndex];
      if (_animationEndPosition == Constants.winningSquare) {
        _celebratePawnReaching100(_animatingPawn!, currentPlayer);
      }

      _checkSpecialSquares();
    }

    // Re-enable dice rolling after move is complete
    setState(() {
      _canRollDice = true;
    });
  }


  void _checkSpecialSquares() {
    final currentPlayer = players[currentPlayerIndex];
    final pawn = currentPlayer.pawns.firstWhere((p) => p.position == _animationEndPosition);

    // Check if pawn reached 100 (before other special squares)
    if (_animationEndPosition == Constants.winningSquare) {
      _celebratePawnReaching100(pawn, currentPlayer);
      return;
    }

    // Check for snakes and ladders FIRST
    if (Constants.snacksAndLaddersMap.containsKey(pawn.position)) {
      int oldPos = pawn.position;
      int newPos = Constants.snacksAndLaddersMap[pawn.position]!;
      if (newPos > oldPos) {
        // Ladder - add bonus coins
        currentPlayer.coins += Constants.ladderBonus;
        _showMessage('${currentPlayer.id} climbed a ladder from $oldPos to $newPos! +${Constants.ladderBonus} coins.');
      } else {
        // Snake - apply penalty
        currentPlayer.coins += Constants.snackPenalty;
        // Ensure coins don't go negative
        if (currentPlayer.coins < 0) currentPlayer.coins = 0;
        _showMessage('${currentPlayer.id} got bitten by a snake from $oldPos to $newPos! ${Constants.snackPenalty} coins.');
      }

      // Animate to new position and return (don't check other squares yet)
      Future.delayed(Duration(seconds: 1), () {
        _animatePawnMove(pawn, newPos);
      });
      return;
    }

    // Only check these if NOT on a snake/ladder square
    if (Constants.goldMineSquares.contains(pawn.position)) {
      currentPlayer.coins += Constants.goldBonus;
      _showMessage('${currentPlayer.id} found a gold mine! +${Constants.goldBonus} coins.');
    }

    // Handle big hole squares - THIS IS THE KEY CHANGE
    if (Constants.bigHoleSquares.contains(pawn.position)) {
      currentPlayer.skipTurn = true; // Set flag to skip NEXT turn
      _showMessage('${currentPlayer.id} fell into a hole! Will skip next turn.');

      // Check for winner
      _checkForWinner();

      // Continue to next player normally (don't skip this turn)
      if (!gameOver) {
        Future.delayed(Duration(seconds: 2), () {
          nextTurn();
        });
      }
      return;
    }

    // Check if player has won (all pawns at 100)
    _checkForWinner();
    if (!gameOver) {
      Future.delayed(Duration(seconds: 2), () {
        nextTurn();
      });
    }
  }






  void _checkForWinner() {
    final currentPlayer = players[currentPlayerIndex];

    // Check if all pawns of current player have reached 100
    bool allPawnsFinished = currentPlayer.pawns.every((pawn) => pawn.position == Constants.winningSquare);

    if (allPawnsFinished && winnerId == null) {
      // This is the first winner
      setState(() {
        winnerId = currentPlayer.id;
        gameOver = false; // Game continues for other players
      });
      _showMessage('${currentPlayer.id} has finished all pawns! 🎉', duration: Duration(seconds: 3));
    }

    // Check if all players have finished (all pawns at 100)
    bool allPlayersFinished = players.every((player) =>
        player.pawns.every((pawn) => pawn.position == Constants.winningSquare));

    if (allPlayersFinished) {
      setState(() {
        gameOver = true;
      });
      _showMessage('Game Over! ${winnerId ?? "No one"} wins!', duration: Duration(seconds: 5));
    }
  }

  void _rollDice() {
    if (diceRolling || gameOver || !_canRollDice) return; // Add !_canRollDice check
    if (_isAI(players[currentPlayerIndex].id)) return;

    if (diceRoll != null && moveablePawns().isNotEmpty) {
      setState(() {
        message = 'Please move a valid pawn before rolling again.';
      });
      return;
    }

    setState(() {
      diceRolling = true;
      _canRollDice = false; // Disable rolling
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
            _canRollDice = true; // Re-enable rolling for next turn
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
      message = '${currentPlayer.id} (AI) is thinking...';
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
      message = '${players[currentPlayerIndex].id} (AI) is rolling...';
    });

    Future.delayed(Duration(seconds: 1), () {
      int roll = _random.nextInt(6) + 1;
      setState(() {
        diceRoll = roll;
        diceRolling = false;
        message = '${players[currentPlayerIndex].id} (AI) rolled a $roll';
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
        message = "${players[currentPlayerIndex].id} (AI) has no valid moves.";
      });
      Future.delayed(Duration(seconds: 2), nextTurn);
      return;
    }

    final selectedPawn = mPawns[_random.nextInt(mPawns.length)];
    setState(() {
      message = '${players[currentPlayerIndex].id} (AI) is moving...';
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

      // Move to next player
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;

      // Skip players who have already finished all pawns
      int attempts = 0;
      while (players[currentPlayerIndex].pawns.every((pawn) => pawn.position == Constants.winningSquare) &&
          attempts < players.length) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
        attempts++;
      }

      final currentPlayer = players[currentPlayerIndex];

      // Check if this player needs to skip their turn due to being on a hole
      if (currentPlayer.skipTurn) {
        message = '${currentPlayer.id}\'s turn - but must skip due to hole!';

        if (!_isAI(currentPlayer.id)) {
          // Show skip dialog for human players
          _showSkipTurnDialog();
        } else {
          // Auto-skip for AI players
          Future.delayed(Duration(seconds: 2), () {
            setState(() {
              currentPlayer.skipTurn = false; // Clear the skip flag
              message = '${currentPlayer.id} (AI) skipped turn due to hole!';
            });

            // Move to the next player after skipping
            Future.delayed(Duration(seconds: 1), () {
              _moveToNextPlayer();
            });
          });
        }
      } else {
        // Normal turn - no skip needed
        message = '${currentPlayer.id}\'s turn.';

        // Start AI turn if it's an AI player
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
          title: Text('Skip Turn'),
          content: Text('You are on a hole! You must skip this turn. Press OK to skip.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  players[currentPlayerIndex].skipTurn = false; // Clear the skip flag
                  message = '${players[currentPlayerIndex].id} skipped turn due to hole!';
                });

                // Move to the next player after skipping
                Future.delayed(Duration(seconds: 1), () {
                  _moveToNextPlayer();
                });
              },
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

      // Move to next player
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;

      // Skip players who have already finished all pawns
      int attempts = 0;
      while (players[currentPlayerIndex].pawns.every((pawn) => pawn.position == Constants.winningSquare) &&
          attempts < players.length) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
        attempts++;
      }

      final currentPlayer = players[currentPlayerIndex];

      // Check if this new player also needs to skip
      if (currentPlayer.skipTurn) {
        message = '${currentPlayer.id}\'s turn - but must skip due to hole!';

        if (!_isAI(currentPlayer.id)) {
          _showSkipTurnDialog();
        } else {
          Future.delayed(Duration(seconds: 2), () {
            setState(() {
              currentPlayer.skipTurn = false;
              message = '${currentPlayer.id} (AI) skipped turn due to hole!';
            });
            Future.delayed(Duration(seconds: 1), () {
              _moveToNextPlayer();
            });
          });
        }
      } else {
        // Normal turn
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
          title: Text('Restart Game'),
          content: Text('Are you sure you want to restart the game?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startNewGame();
                main(); //my change
              },
              child: Text('Restart'),
            ),
          ],
        );
      },
    );
  }

  Widget _getPawnImage(String playerId, {double size = 20}) {
    final imagePath = pawnImages[playerId];
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _getPlayerColor(playerId),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Center(
              child: Text(
                playerId[0],
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getPlayerColor(playerId),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Text(
          playerId[0],
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getPlayerColor(String playerId) {
    final index = widget.playerNames.indexOf(playerId);
    final colors = [Colors.blue, Colors.red, Colors.yellow, Colors.green];
    return index >= 0 && index < colors.length ? colors[index] : Colors.grey;
  }

  Widget buildBoard() {
    List<Widget> squares = [];
    for (int i = 1; i <= 100; i++) {
      int row = 9 - ((i - 1) ~/ 10); // Row from bottom (0) to top (9)
      bool isEvenRow = (row % 2 == 0);
      int col = isEvenRow ? 9 - ((i - 1) % 10) : (i - 1) % 10;

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
                      child: Icon(
                        Icons.android,
                        size: 10,
                        color: Colors.grey,
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

      squares.add(Positioned(
        left: col * 40.0,
        top: row * 40.0,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            color: Colors.transparent,
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "$i",
                  style: TextStyle(fontSize: 10, color: Colors.black54),
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

  Widget buildBasePawnsArea() {
    final player = players[currentPlayerIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${player.id}\'s Base',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (_isAI(player.id))
              Icon(Icons.computer, size: 16, color: Colors.grey),
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
              child: Opacity(
                opacity: isInBase ? 1.0 : 0.4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
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
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (_isAI(player.id))
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Icon(
                              Icons.android,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pawn ${idx + 1}',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget buildPlayersInfoRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: players.map((player) {
          bool isCurrent = player == players[currentPlayerIndex];
          int baseCount = player.pawns.where((pawn) => pawn.position == 0).length;
          int finishedCount = player.pawns.where((pawn) => pawn.position == Constants.winningSquare).length;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 6),
            constraints: BoxConstraints(maxWidth: 150),
            child: Card(
              color: isCurrent ? Colors.blue.withOpacity(0.1) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: player.id,
                          child: Text(
                            _truncateText(player.id, 12),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (_isAI(player.id))
                          Icon(Icons.android, size: 12, color: Colors.grey),
                        if (winnerId == player.id)
                          Icon(Icons.emoji_events, size: 12, color: Colors.amber),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                        SizedBox(width: 4),
                        Text('${player.coins}', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 12),
                        Icon(Icons.flag, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text('$finishedCount/4', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: player.pawns.map((pawn) {
                        bool isOnBoard = pawn.position != 0;
                        bool isFinished = pawn.position == Constants.winningSquare;
                        return Opacity(
                          opacity: isOnBoard ? 0.4 : 1.0,
                          child: Stack(
                            children: [
                              _getPawnImage(player.id, size: 16),
                              if (isFinished)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Icon(Icons.check, size: 10, color: Colors.green),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'AI\nTurn',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _canRollDice ? _rollDice : null, // Only allow tap if canRollDice is true
      child: Opacity(
        opacity: _canRollDice ? 1.0 : 0.5, // Show as semi-transparent when disabled
        child: AnimatedDice(
          diceValue: diceRoll,
          rolling: diceRolling,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SNACKS & LADDERS',
          style: GoogleFonts.pressStart2p(
            fontSize: 16,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 8.0,
                color: Colors.purple,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 10,
        shadowColor: Colors.purpleAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _showResetConfirmation,
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.deepPurple[200]!, Colors.grey[700]!],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                buildPlayersInfoRow(),
                SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                buildAnimatedDice(),
                SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.fitWidth, //my change
                      child: SizedBox(
                        width: 400,
                        height: 400,
                        child: Stack(
                          children: [
                            Image.asset(
                              'assets/board_bg.png',
                              width: 400,
                              height: 400,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 400,
                                  height: 400,
                                  color: Colors.brown[100],
                                  child: Center(
                                    child: Text(
                                      'Game Board',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                SizedBox(height: 8),
                buildBasePawnsArea(),
                SizedBox(height: 12),
              ],
            ),
          ),

          if (_showSpecialMessage)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _specialSquareMessage,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedDice extends StatefulWidget {
  final int? diceValue;
  final bool rolling;

  AnimatedDice({required this.diceValue, required this.rolling});

  @override
  _AnimatedDiceState createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
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
        width: 60,
        height: 60,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: widget.diceValue != null
                  ? Text(
                '${widget.diceValue}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
                  : Icon(Icons.casino, size: 30),
            ),
          );
        },
      ),
    );
  }
}