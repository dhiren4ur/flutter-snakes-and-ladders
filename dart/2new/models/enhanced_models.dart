
enum GameStatus {
  setup,
  inProgress,
  paused,
  gameOver,
}

enum PlayerType {
  human,
  ai,
}

enum SquareType {
  normal,
  ladder,
  snake,
  goldMine,
  hole,
  home,
}

class PawnState {
  final int id;
  int position; // 0 for base, 1-100 for board, 100 for home
  int displayPosition; // Current displayed position for animation
  bool isAnimating;
  bool isSelected;

  PawnState(this.id, this.position)
      : displayPosition = position,
        isAnimating = false,
        isSelected = false;

  // Copy constructor for state management
  PawnState copy() {
    return PawnState(id, position)
      ..displayPosition = displayPosition
      ..isAnimating = isAnimating
      ..isSelected = isSelected;
  }

  // Check if pawn is at home
  bool get isAtHome => position == 100;
  
  // Check if pawn is in base
  bool get isInBase => position == 0;
  
  // Check if pawn is on board
  bool get isOnBoard => position > 0 && position < 100;
}

class PlayerData {
  final String id;
  final PlayerType type;
  List<PawnState> pawns;
  int coins; // Hidden coin system for future features
  bool skipTurn;
  bool showSkipDialog;
  int gamesWon;
  int totalMoves;
  DateTime? lastMoveTime;

  PlayerData({
    required this.id,
    required this.pawns,
    this.type = PlayerType.human,
    this.coins = 0,
    this.skipTurn = false,
    this.showSkipDialog = false,
    this.gamesWon = 0,
    this.totalMoves = 0,
    this.lastMoveTime,
  });

  // Get number of pawns at home
  int get pawnsAtHome => pawns.where((pawn) => pawn.isAtHome).length;
  
  // Get number of pawns in base
  int get pawnsInBase => pawns.where((pawn) => pawn.isInBase).length;
  
  // Get number of pawns on board
  int get pawnsOnBoard => pawns.where((pawn) => pawn.isOnBoard).length;
  
  // Check if player has won (all pawns at home)
  bool get hasWon => pawns.every((pawn) => pawn.isAtHome);
  
  // Check if player is AI
  bool get isAI => type == PlayerType.ai;
  
  // Get player progress (0.0 to 1.0)
  double get progress {
    int totalProgress = pawns.fold(0, (sum, pawn) => sum + pawn.position);
    return totalProgress / (4 * 100); // 4 pawns * 100 squares each
  }

  // Reset player for new game
  void reset() {
    for (int i = 0; i < pawns.length; i++) {
      pawns[i] = PawnState(i, 0);
    }
    skipTurn = false;
    showSkipDialog = false;
    totalMoves = 0;
    lastMoveTime = null;
  }

  // Add move to statistics
  void addMove() {
    totalMoves++;
    lastMoveTime = DateTime.now();
  }
}

class GameState {
  List<PlayerData> players;
  int currentPlayerIndex;
  int? diceRoll;
  bool diceRolling;
  String message;
  GameStatus status;
  String? winnerId;
  List<String> finishOrder;
  DateTime gameStartTime;
  Duration gameDuration;
  int totalTurns;

  GameState({
    required this.players,
    this.currentPlayerIndex = 0,
    this.diceRoll,
    this.diceRolling = false,
    this.message = '',
    this.status = GameStatus.setup,
    this.winnerId,
    List<String>? finishOrder,
    DateTime? gameStartTime,
    Duration? gameDuration,
    this.totalTurns = 0,
  })  : finishOrder = finishOrder ?? [],
        gameStartTime = gameStartTime ?? DateTime.now(),
        gameDuration = gameDuration ?? Duration.zero;

  // Get current player
  PlayerData get currentPlayer => players[currentPlayerIndex];
  
  // Check if game is over
  bool get isGameOver => status == GameStatus.gameOver;
  
  // Check if game is in progress
  bool get isInProgress => status == GameStatus.inProgress;
  
  // Get game statistics
  Map<String, dynamic> get statistics => {
    'totalTurns': totalTurns,
    'gameDuration': gameDuration,
    'playersFinished': finishOrder.length,
    'winner': winnerId,
  };

  // Move to next player
  void nextPlayer() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    
    // Skip players who have already finished
    int attempts = 0;
    while (currentPlayer.hasWon && attempts < players.length) {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      attempts++;
    }
    
    totalTurns++;
  }

  // End game
  void endGame() {
    status = GameStatus.gameOver;
    gameDuration = DateTime.now().difference(gameStartTime);
  }

  // Reset game state
  void reset() {
    for (var player in players) {
      player.reset();
    }
    currentPlayerIndex = 0;
    diceRoll = null;
    diceRolling = false;
    message = '';
    status = GameStatus.inProgress;
    winnerId = null;
    finishOrder.clear();
    gameStartTime = DateTime.now();
    gameDuration = Duration.zero;
    totalTurns = 0;
  }
}

class GameMove {
  final String playerId;
  final int pawnId;
  final int fromPosition;
  final int toPosition;
  final int diceRoll;
  final DateTime timestamp;
  final String? special; // ladder, snake, hole, goldmine

  GameMove({
    required this.playerId,
    required this.pawnId,
    required this.fromPosition,
    required this.toPosition,
    required this.diceRoll,
    required this.timestamp,
    this.special,
  });

  // Convert to string for logging
  @override
  String toString() {
    return '$playerId moved pawn $pawnId from $fromPosition to $toPosition (rolled $diceRoll)${special != null ? ' - $special' : ''}';
  }
}

class GameSettings {
  bool soundEffects;
  bool backgroundMusic;
  bool animations;
  bool vibration;
  double gameSpeed;
  int selectedTheme;
  bool showCoins; // For future coin system toggle

  GameSettings({
    this.soundEffects = true,
    this.backgroundMusic = true,
    this.animations = true,
    this.vibration = true,
    this.gameSpeed = 1.0,
    this.selectedTheme = 0,
    this.showCoins = false, // Hidden by default
  });

  // Apply settings to game
  void apply() {
    // Implementation for applying settings
  }

  // Save settings to storage
  Future<void> save() async {
    // Implementation for saving settings
  }

  // Load settings from storage
  static Future<GameSettings> load() async {
    // Implementation for loading settings
    return GameSettings();
  }
}

// Achievement system for future implementation
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
  });
}

// Leaderboard entry for future implementation
class LeaderboardEntry {
  final String playerName;
  final int gamesWon;
  final int gamesPlayed;
  final double averageMovesPerGame;
  final Duration averageGameTime;
  final DateTime lastPlayed;

  LeaderboardEntry({
    required this.playerName,
    required this.gamesWon,
    required this.gamesPlayed,
    required this.averageMovesPerGame,
    required this.averageGameTime,
    required this.lastPlayed,
  });

  double get winPercentage => gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;
}
