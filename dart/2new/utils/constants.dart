
class Constants {
  // Game Board
  static const int boardSize = 100;
  static const int winningSquare = 100;
  static const int pawnsPerPlayer = 4;
  static const int startRoll = 1;
  static const int turnDuration = 15;

  // Ladders (healthy snacks) - Green squares that boost you up
  static const Map<int, int> snacksAndLaddersMap = {
    // Ladders (positive moves)
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
    
    // Snakes (negative moves)  
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
  static const List<int> bigHoleSquares = [27, 57, 86]; // Skip turn
  static const List<int> goldMineSquares = [10, 20, 30, 50, 61, 70]; // Bonus coins (hidden feature)

  // Rewards and penalties (for future coin system)
  static const int ladderBonus = 20;
  static const int snackPenalty = -10;
  static const int goldBonus = 30;

  // Player configurations
  static const List<String> playerIds = ['Player 1', 'Player 2', 'Player 3', 'Player 4'];
  
  static const Map<String, PlayerConfig> playerConfigs = {
    'Player 1': PlayerConfig('Player 1', 0xFF3B82F6, 0xFF1E40AF),
    'Player 2': PlayerConfig('Player 2', 0xFFEF4444, 0xFF991B1B),
    'Player 3': PlayerConfig('Player 3', 0xFFF59E0B, 0xFFB45309),
    'Player 4': PlayerConfig('Player 4', 0xFF10B981, 0xFF059669),
  };

  // Animation durations
  static const Duration diceRollDuration = Duration(milliseconds: 1000);
  static const Duration pawnMoveDuration = Duration(milliseconds: 300);
  static const Duration messageDisplayDuration = Duration(seconds: 2);
  static const Duration aiThinkingDuration = Duration(seconds: 1);

  // Game messages
  static const String gameTitle = 'SNAKES & LADDERS';
  static const String gameSubtitle = 'Professional Edition';
  
  // Board layout constants
  static const double boardSquareSize = 40.0;
  static const double pawnSize = 20.0;
  static const double largePawnSize = 28.0;
  
  // Special square indicators
  static String getSquareDescription(int position) {
    if (snacksAndLaddersMap.containsKey(position)) {
      int destination = snacksAndLaddersMap[position]!;
      if (destination > position) {
        return 'Ladder: Climb to $destination';
      } else {
        return 'Snake: Slide to $destination';
      }
    }
    
    if (bigHoleSquares.contains(position)) {
      return 'Hole: Skip next turn';
    }
    
    if (goldMineSquares.contains(position)) {
      return 'Gold Mine: Bonus coins';
    }
    
    return 'Regular square';
  }

  // Check if square is a ladder
  static bool isLadder(int position) {
    return snacksAndLaddersMap.containsKey(position) && 
           snacksAndLaddersMap[position]! > position;
  }

  // Check if square is a snake
  static bool isSnake(int position) {
    return snacksAndLaddersMap.containsKey(position) && 
           snacksAndLaddersMap[position]! < position;
  }

  // Check if square is special
  static bool isSpecialSquare(int position) {
    return snacksAndLaddersMap.containsKey(position) ||
           bigHoleSquares.contains(position) ||
           goldMineSquares.contains(position);
  }
}

class PlayerConfig {
  final String id;
  final int fillColor;
  final int strokeColor;

  const PlayerConfig(this.id, this.fillColor, this.strokeColor);
}

// Game difficulty levels (for future AI enhancement)
enum GameDifficulty {
  easy,
  medium,
  hard,
  expert,
}

// Sound effect types (for future audio system)
enum SoundEffect {
  diceRoll,
  pawnMove,
  ladderClimb,
  snakeBite,
  goldMine,
  hole,
  win,
  turnChange,
}

// Animation types
enum AnimationType {
  none,
  basic,
  smooth,
  advanced,
}
