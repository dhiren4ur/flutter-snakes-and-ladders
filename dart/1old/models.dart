enum GameStatus {
  setup,
  inProgress,
  gameOver,
}

class PawnState {
  final int id;
  int position;  // 0 for base, 1-100 for board, 100 for home
  int displayPosition; // Current displayed position for animation
  bool isAnimating;

  PawnState(this.id, this.position) :
        displayPosition = position,
        isAnimating = false;
}

class PlayerData {
  final String id;
  List<PawnState> pawns;
  int coins;
  bool skipTurn;
  bool showSkipDialog;

  PlayerData({
    required this.id,
    required this.pawns,
    this.coins = 0,
    this.skipTurn = false,
    this.showSkipDialog = false,
  });
}