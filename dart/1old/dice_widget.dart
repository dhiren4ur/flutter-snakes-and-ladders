import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class DiceWidget extends StatefulWidget {
  final int? diceValue;  // null means not rolled yet
  final bool rolling;
  final VoidCallback onRoll;
  final Random random; // Pass random instance from parent

  DiceWidget({required this.diceValue, required this.rolling, required this.onRoll, required this.random});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  late Timer? _timer;
  late Timer? _animationTimer;
  int? _currentFace;

  @override
  void initState() {
    super.initState();
    _currentFace = widget.diceValue;
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling) {
      _startRolling();
    } else {
      _stopRolling();
      setState(() {
        _currentFace = widget.diceValue;
      });
    }
  }

  void _startRolling() {
    _timer?.cancel();
    _animationTimer?.cancel();

    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _currentFace = widget.random.nextInt(6) + 1;
      });
    });

    _animationTimer = Timer(Duration(seconds: 1), () {
      _stopRolling();
      setState(() {
        _currentFace = widget.diceValue;
      });
    });
  }

  void _stopRolling() {
    _timer?.cancel();
    _animationTimer?.cancel();
  }

  @override
  void dispose() {
    _stopRolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String imageAsset;

    if (_currentFace == null) {
      imageAsset = 'assets/dice_idle.png';
    } else {
      imageAsset = 'assets/dice_${_currentFace}.png';
    }

    return GestureDetector(
      onTap: widget.rolling ? null : widget.onRoll,
      child: Image.asset(
        imageAsset,
        width: 60,
        height: 60,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _currentFace != null
                  ? Text(
                '$_currentFace',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
                  : Icon(Icons.casino, size: 30),
            ),
          );
        },
      ),
    );
  }
}