class Constants {
  static const int boardSize = 100;
  static const int winningSquare = 100;
  static const int pawnsPerPlayer = 4;
  static const int startRoll = 1;
  static const int turnDuration = 15;

  // Ladders (healthy snacks)
  static const Map<int, int> snacksAndLaddersMap = {
    2: 38,
    7: 14,
    8: 31,
    15: 26,
    21: 42,
    28: 84,
    36: 44,
    51: 67,
    78: 98,
    71: 91,
    87: 94,

    // Snacks (unhealthy snacks)
    16: 6,
    49: 11,
    46: 25,
    62: 19,
    64: 60,
    74: 53,
    89: 68,
    92: 88,
    95: 75,
    99: 80,
  };

  static const List<int> bigHoleSquares = [27, 57, 86]; // Skip turn
  static const List<int> goldMineSquares = [10,20,30,50,61,70]; // Get bonus coins

  static const int ladderBonus = 20;
  static const int snackPenalty = -10;
  static const int goldBonus = 30;

  static const List<String> playerIds = ['Player 1', 'Player 2', 'Player 3', 'Player 4'];

  static const Map<String, PlayerConfig> playerConfigs = {
    'Player 1': PlayerConfig('Player 1', 0xFF3B82F6, 0xFF1E40AF),
    'Player 2': PlayerConfig('Player 2', 0xFFEF4444, 0xFF991B1B),
    'Player 3': PlayerConfig('Player 3', 0xFFF59E00, 0xFFB45300),
    'Player 4': PlayerConfig('Player 4', 0xFF22C55E, 0xFF15803D),
  };
}

class PlayerConfig {
  final String id;
  final int fillColor;
  final int strokeColor;

  const PlayerConfig(this.id, this.fillColor, this.strokeColor);
}