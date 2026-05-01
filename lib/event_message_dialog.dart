import 'dart:async';

import 'package:flutter/material.dart';

/// Enhanced event message dialog for special game events
/// Features: Large text, longer display, manual close button
class EventMessageDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? titleColor;
  final Duration displayDuration;
  final VoidCallback? onClose;

  const EventMessageDialog({
    required this.title,
    required this.message,
    this.icon,
    this.titleColor,
    this.displayDuration = const Duration(seconds: 6),
    this.onClose,
  });

  @override
  State<EventMessageDialog> createState() => _EventMessageDialogState();
}

class _EventMessageDialogState extends State<EventMessageDialog> {
  late Timer _autoCloseTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startAutoClose();
  }

  void _startAutoClose() {
    _autoCloseTimer = Timer(widget.displayDuration, () {
      if (mounted && !_isDisposed) {
        Navigator.of(context).pop();
        widget.onClose?.call();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoCloseTimer.cancel();
    super.dispose();
  }

  void _closeDialog() {
    if (mounted) {
      Navigator.of(context).pop();
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetAnimationDuration: const Duration(milliseconds: 300),
      insetAnimationCurve: Curves.easeOut,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.titleColor ?? Colors.blue,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon if provided
              if (widget.icon != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Icon(
                    widget.icon,
                    size: 56,
                    color: widget.titleColor ?? Colors.blue,
                  ),
                ),

              // Title - LARGE TEXT
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 36, // LARGER
                  fontWeight: FontWeight.bold,
                  color: widget.titleColor ?? Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 20),

              // Message - LARGE TEXT
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 22, // LARGER
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 28),

              // Close Button
              ElevatedButton(
                onPressed: _closeDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.titleColor ?? Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show event dialog with pre-configured settings
Future<void> showEventDialog({
  required BuildContext context,
  required String title,
  required String message,
  IconData? icon,
  Color? titleColor,
  Duration? duration,
  VoidCallback? onClose,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => EventMessageDialog(
      title: title,
      message: message,
      icon: icon,
      titleColor: titleColor,
      displayDuration: duration ?? const Duration(seconds: 6),
      onClose: onClose,
    ),
  );
}

/// Pre-configured dialogs for specific events
class GameDialogs {
  static Future<void> showLadderClimb(BuildContext context) {
    return showEventDialog(
      context: context,
      title: '🪜 Ladder Climb!',
      message: 'You climbed a ladder!\nMove up the board!',
      icon: Icons.trending_up,
      titleColor: Colors.green,
      duration: const Duration(seconds: 5),
    );
  }

  static Future<void> showSnakeBite(BuildContext context) {
    return showEventDialog(
      context: context,
      title: '🐍 Snake Bite!',
      message: 'Oh no! A snake got you.\nSlide back down!',
      icon: Icons.trending_down,
      titleColor: Colors.red,
      duration: const Duration(seconds: 5),
    );
  }

  static Future<void> showGoldMine(BuildContext context) {
    return showEventDialog(
      context: context,
      title: '💰 Gold Mine!',
      message: 'Lucky find!\n+30 Coins & Extra Turn!',
      icon: Icons.star,
      titleColor: Colors.amber,
      duration: const Duration(seconds: 6),
    );
  }

  static Future<void> showHoleFall(BuildContext context) {
    return showEventDialog(
      context: context,
      title: '🕳️ Hole!',
      message: 'Fell into a hole.\nYou will skip next turn.',
      icon: Icons.warning,
      titleColor: Colors.orange,
      duration: const Duration(seconds: 5),
    );
  }

  static Future<void> showWinner(
      BuildContext context,
      String playerName,
      ) {
    return showEventDialog(
      context: context,
      title: '🎉 WINNER!',
      message: '$playerName reached 100!\n\nCongratulations!',
      icon: Icons.celebration,
      titleColor: Colors.purple,
      duration: const Duration(seconds: 8),
    );
  }

  static Future<void> showExtraRoll(BuildContext context) {
    return showEventDialog(
      context: context,
      title: '🎲 Extra Turn!',
      message: 'Got 6 or landed on bonus!\nRoll again!',
      icon: Icons.refresh,
      titleColor: Colors.blue,
      duration: const Duration(seconds: 4),
    );
  }
}
