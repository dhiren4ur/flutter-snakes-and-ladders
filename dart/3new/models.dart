enum GameStatus {
  setup,
  inProgress,
  gameOver,
  paused,
}

enum PawnAnimationType {
  none,
  move,
  jump,
  celebration,
}

enum SquareType {
  normal,
  ladder,
  snake,
  hole,
  goldMine,
  start,
  finish,
}

class PawnState {
  final int id;
  int position; // 0 for base, 1-100 for board, 100 for home
  int displayPosition; // Current displayed position for animation
  bool isAnimating;
  PawnAnimationType animationType;

  PawnState(this.id, this.position) :
        displayPosition = position,
        isAnimating = false,
        animationType = PawnAnimationType.none;

  // Convenience methods
  bool get isInBase => position == 0;
  bool get isOnBoard => position > 0 && position < 100;
  bool get hasFinished => position == 100;
  
  // Create a copy with updated values
  PawnState copyWith({
    int? position,
    int? displayPosition,
    bool? isAnimating,
    PawnAnimationType? animationType,
  }) {
    final newPawn = PawnState(id, position ?? this.position);
    newPawn.displayPosition = displayPosition ?? this.displayPosition;
    newPawn.isAnimating = isAnimating ?? this.isAnimating;
    newPawn.animationType = animationType ?? this.animationType;
    return newPawn;
  }
}

class PlayerData {
  final String id;
  final bool isAI;
  List<PawnState> pawns;
  int coins; // Hidden scoring system
  bool skipTurn;
  bool showSkipDialog;
  DateTime? lastMoveTime;
  int totalMoves;
  int finishedPawns;

  PlayerData({
    required this.id,
    required this.pawns,
    this.isAI = false,
    this.coins = 0,
    this.skipTurn = false,
    this.showSkipDialog = false,
    this.lastMoveTime,
    this.totalMoves = 0,
    this.finishedPawns = 0,
  });

  // Convenience methods
  bool get hasFinishedAllPawns => pawns.every((pawn) => pawn.hasFinished);
  int get pawnsInBase => pawns.where((pawn) => pawn.isInBase).length;
  int get pawnsOnBoard => pawns.where((pawn) => pawn.isOnBoard).length;
  int get pawnsFinished => pawns.where((pawn) => pawn.hasFinished).length;
  
  // Calculate player progress (0.0 to 1.0)
  double get gameProgress {
    int totalProgress = pawns.fold(0, (sum, pawn) => sum + pawn.position);
    return totalProgress / 400.0; // Max progress is 4 pawns * 100 squares
  }

  void addCoins(int amount) {
    coins = (coins + amount).clamp(0, 9999);
  }

  void recordMove() {
    totalMoves++;
    lastMoveTime = DateTime.now();
  }
}

class GameState {
  final List<PlayerData> players;
  final int currentPlayerIndex;
  final int? lastDiceRoll;
  final bool isDiceRolling;
  final GameStatus status;
  final String? winnerId;
  final String currentMessage;
  final DateTime gameStartTime;
  final Duration gameDuration;

  GameState({
    required this.players,
    required this.currentPlayerIndex,
    this.lastDiceRoll,
    this.isDiceRolling = false,
    this.status = GameStatus.setup,
    this.winnerId,
    this.currentMessage = '',
    DateTime? gameStartTime,
    Duration? gameDuration,
  }) : gameStartTime = gameStartTime ?? DateTime.now(),
       gameDuration = gameDuration ?? Duration.zero;

  PlayerData get currentPlayer => players[currentPlayerIndex];
  bool get isGameOver => status == GameStatus.gameOver;
  bool get hasWinner => winnerId != null;

  GameState copyWith({
    List<PlayerData>? players,
    int? currentPlayerIndex,
    int? lastDiceRoll,
    bool? isDiceRolling,
    GameStatus? status,
    String? winnerId,
    String? currentMessage,
    Duration? gameDuration,
  }) {
    return GameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      lastDiceRoll: lastDiceRoll ?? this.lastDiceRoll,
      isDiceRolling: isDiceRolling ?? this.isDiceRolling,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      currentMessage: currentMessage ?? this.currentMessage,
      gameStartTime: gameStartTime,
      gameDuration: gameDuration ?? this.gameDuration,
    );
  }
}

class SpecialSquare {
  final int position;
  final SquareType type;
  final String title;
  final String description;
  final String emoji;

  const SpecialSquare({
    required this.position,
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
  });
}

class GameMove {
  final String playerId;
  final int pawnId;
  final int fromPosition;
  final int toPosition;
  final int diceRoll;
  final DateTime timestamp;
  final SquareType? specialSquareType;

  GameMove({
    required this.playerId,
    required this.pawnId,
    required this.fromPosition,
    required this.toPosition,
    required this.diceRoll,
    DateTime? timestamp,
    this.specialSquareType,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return '$playerId moved pawn $pawnId from $fromPosition to $toPosition (rolled $diceRoll)';
  }
}

class AIPlayer {
  final String name;
  final String difficulty;
  final int thinkingTimeMs;
  final double aggressiveness; // 0.0 to 1.0

  const AIPlayer({
    required this.name,
    this.difficulty = 'Normal',
    this.thinkingTimeMs = 2000,
    this.aggressiveness = 0.5,
  });

  static const List<AIPlayer> presets = [
    AIPlayer(name: 'CobraBot', difficulty: 'Easy', thinkingTimeMs: 1000, aggressiveness: 0.3),
    AIPlayer(name: 'Laddie', difficulty: 'Normal', thinkingTimeMs: 2000, aggressiveness: 0.5),
    AIPlayer(name: 'DiceMaster', difficulty: 'Hard', thinkingTimeMs: 3000, aggressiveness: 0.8),
  ];
}

// Statistics and achievements (for future features)
class PlayerStats {
  final String playerId;
  int gamesPlayed;
  int gamesWon;
  int totalMoves;
  int fastestWin; // in moves
  DateTime lastPlayed;

  PlayerStats({
    required this.playerId,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.totalMoves = 0,
    this.fastestWin = 999,
    DateTime? lastPlayed,
  }) : lastPlayed = lastPlayed ?? DateTime.now();

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0.0;
  double get averageMovesPerGame => gamesPlayed > 0 ? totalMoves / gamesPlayed : 0.0;
}
