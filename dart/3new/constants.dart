
class Constants {
  static const int boardSize = 100;
  static const int winningSquare = 100;
  static const int pawnsPerPlayer = 4;
  static const int startRoll = 1;
  static const int turnDuration = 15;

  // Ladders (healthy snacks) - Green squares that move you up
  static const Map<int, int> snacksAndLaddersMap = {
    // Ladders (climb up)
    2: 38,
    7: 14,
    8: 31,
    15: 26,
    21: 42,
    28: 84,
    36: 44,
    51: 67,
    71: 91,
    78: 98,
    87: 94,

    // Snakes (slide down) - Red squares that move you down
    16: 6,
    46: 25,
    49: 11,
    62: 19,
    64: 60,
    74: 53,
    89: 68,
    92: 88,
    95: 75,
    99: 80,
  };

  // Special squares
  static const List<int> bigHoleSquares = [27, 57, 86]; // Skip turn - Brown squares
  static const List<int> goldMineSquares = [10, 20, 30, 50, 61, 70]; // Get bonus coins - Yellow squares

  // Coin system (hidden from UI but functional)
  static const int ladderBonus = 20;
  static const int snackPenalty = -10;
  static const int goldBonus = 30;

  // Default player configurations
  static const List<String> playerIds = ['Player 1', 'Player 2', 'Player 3', 'Player 4'];

  static const Map<String, PlayerConfig> playerConfigs = {
    'Player 1': PlayerConfig('Player 1', 0xFF3B82F6, 0xFF1E40AF),
    'Player 2': PlayerConfig('Player 2', 0xFFEF4444, 0xFF991B1B),
    'Player 3': PlayerConfig('Player 3', 0xFFF59E00, 0xFFB45300),
    'Player 4': PlayerConfig('Player 4', 0xFF22C55E, 0xFF15803D),
  };

  // Game settings
  static const Duration moveAnimationDuration = Duration(milliseconds: 400);
  static const Duration specialSquareMessageDuration = Duration(seconds: 2);
  static const Duration celebrationMessageDuration = Duration(seconds: 3);
}

class PlayerConfig {
  final String id;
  final int fillColor;
  final int strokeColor;

  const PlayerConfig(this.id, this.fillColor, this.strokeColor);
}

// Game difficulty settings (for future use)
class GameDifficulty {
  static const String easy = 'Easy';
  static const String normal = 'Normal';
  static const String hard = 'Hard';
  
  static const Map<String, int> aiThinkingTime = {
    easy: 1000,    // 1 second
    normal: 2000,  // 2 seconds
    hard: 3000,    // 3 seconds
  };
}
