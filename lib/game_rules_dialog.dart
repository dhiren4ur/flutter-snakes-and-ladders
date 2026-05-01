import 'dart:async';

import 'package:flutter/material.dart';

/// Enhanced Game Rules Dialog
/// Feature 7: Auto-close after countdown + manual close button
class GameRulesDialog extends StatefulWidget {
  final VoidCallback? onAutoClose;
  final VoidCallback? onManualClose;

  const GameRulesDialog({
    this.onAutoClose,
    this.onManualClose,
  });

  @override
  State<GameRulesDialog> createState() => _GameRulesDialogState();
}

class _GameRulesDialogState extends State<GameRulesDialog> {
  late Timer _autoCloseTimer;
  int _secondsLeft = 10;  // Feature 7: Auto-close countdown

  @override
  void initState() {
    super.initState();
    _startAutoCloseTimer();
  }

  void _startAutoCloseTimer() {
    _autoCloseTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          timer.cancel();
          _autoClose();
        }
      });
    });
  }

  void _autoClose() {
    if (mounted) {
      Navigator.pop(context);
      widget.onAutoClose?.call();
    }
  }

  void _manualClose() {
    _autoCloseTimer.cancel();
    Navigator.pop(context);
    widget.onManualClose?.call();
  }

  @override
  void dispose() {
    _autoCloseTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetAnimationDuration: const Duration(milliseconds: 400),
      insetAnimationCurve: Curves.easeOut,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blue, width: 3),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ========== TITLE ==========
                Text(
                  'GAME RULES',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                // ========== RULES LIST ==========
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildRule(
                        '1',
                        'Roll the Dice',
                        'Click the dice button to roll. Get a number from 1-6.',
                        Icons.casino,
                      ),
                      SizedBox(height: 16),
                      _buildRule(
                        '2',
                        'Move Your Pawn',
                        'Tap a pawn to select it, then move it forward by the number shown.',
                        Icons.directions_walk,
                      ),
                      SizedBox(height: 16),
                      _buildRule(
                        '3',
                        'Climb Ladders',
                        'Land on a ladder to climb up and get bonus coins!',
                        Icons.trending_up,
                      ),
                      SizedBox(height: 16),
                      _buildRule(
                        '4',
                        'Avoid Snakes',
                        'Watch out for snakes! They will slide you down the board.',
                        Icons.trending_down,
                      ),
                      SizedBox(height: 16),
                      _buildRule(
                        '5',
                        'Gold Mines',
                        'Land on a gold mine to get +30 coins and an extra turn!',
                        Icons.star,
                      ),
                      SizedBox(height: 16),
                      _buildRule(
                        '6',
                        'Hole Danger',
                        'Fall in a hole and you will skip your next turn.',
                        Icons.warning,
                      ),
                      SizedBox(height: 16),
                      _buildRule(
                        '7',
                        'Reach 100 to Win',
                        'Be the first to reach square 100 to win the game!',
                        Icons.celebration,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // ========== ACTION BUTTONS ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Close Button
                    ElevatedButton(
                      onPressed: _manualClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'I Understand',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Auto-close countdown indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Auto Close',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$_secondsLeft s',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Info text
                Text(
                  'Dialog will close automatically in $_secondsLeft seconds',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build individual rule with icon and text
  Widget _buildRule(
      String number,
      String title,
      String description,
      IconData icon,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper function to show game rules
Future<void> showGameRulesDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => GameRulesDialog(
      onAutoClose: () {
        // Auto-close action
      },
      onManualClose: () {
        // Manual close action
      },
    ),
  );
}
