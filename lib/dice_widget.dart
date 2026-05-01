import 'package:flutter/material.dart';

/// Enhanced Dice Widget with Features 2 & 3:
/// - Feature 2: Disable dice button during player turn
/// - Feature 3: Glow dice button when ready to roll
class DiceWidget extends StatelessWidget {
  final int diceValue;
  final VoidCallback onPressed;
  final bool diceRolling;
  final bool isEnabled;  // Feature 2: NEW - Enable/disable dice button
  final bool shouldGlow;  // Feature 3: NEW - Make dice glow

  const DiceWidget({
    required this.diceValue,
    required this.onPressed,
    required this.diceRolling,
    required this.isEnabled,  // Feature 2: NEW
    required this.shouldGlow,  // Feature 3: NEW
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: isEnabled && !diceRolling ? onPressed : null,  // Feature 2: Check enabled
        child: MouseRegion(
          cursor: (isEnabled && !diceRolling)
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              // ========== Feature 2: Color based on enabled state ==========
              color: isEnabled
                  ? Colors.blue.shade400
                  : Colors.grey.shade400,

              // ========== Feature 3: Glow effect when ready ==========
              boxShadow: shouldGlow
                  ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.8),
                  blurRadius: 25,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],

              // ========== Feature 3: Animated border when glowing ==========
              border: Border.all(
                color: shouldGlow ? Colors.blue.shade300 : Colors.blue.shade600,
                width: shouldGlow ? 4 : 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main dice display
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.blue.shade800,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: diceRolling ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            diceValue.toString(),
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          Text(
                            'DICE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ========== Feature 2: Disabled overlay ==========
                if (!isEnabled)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                // ========== Feature 3: Glow indicator pulse ==========
                if (shouldGlow && !diceRolling)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: AlwaysStoppedAnimation(0.5),
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Rolling indicator
                if (diceRolling)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ),
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

/// Helper widget for showing dice status
class DiceStatusIndicator extends StatelessWidget {
  final bool isEnabled;
  final bool shouldGlow;

  const DiceStatusIndicator({
    required this.isEnabled,
    required this.shouldGlow,
  });

  @override
  Widget build(BuildContext context) {
    String status = isEnabled
        ? (shouldGlow ? 'Ready to Roll' : 'Rolling...')
        : 'Wait for your turn';

    Color statusColor = isEnabled
        ? (shouldGlow ? Colors.green : Colors.orange)
        : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
