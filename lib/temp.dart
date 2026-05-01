for (int index = 0; index < pawnsHere.length; index++) {
  final pawn = pawnsHere[index];
  double pawnSize = pawnsHere.length <= 4 ? 16.0 : 20.0;
  int rowPos = index ~/ 2;
  int colPos = index % 2;
  double left = colPos * 14.0;
  double top = rowPos * 14.0;

  bool isSelected = selectedPawn == pawn;

  positionedPawns.add(
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
                      color: player.color,
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}