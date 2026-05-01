
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DiceWidget extends StatefulWidget {
  final int? diceValue; // null means not rolled yet
  final bool rolling;
  final VoidCallback onRoll;
  final Random random; // Pass random instance from parent
  final bool enabled;
  final double size;

  const DiceWidget({
    Key? key,
    required this.diceValue,
    required this.rolling,
    required this.onRoll,
    required this.random,
    this.enabled = true,
    this.size = 60,
  }) : super(key: key);

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> 
    with SingleTickerProviderStateMixin {
  late Timer? _timer;
  late Timer? _animationTimer;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  int? _currentFace;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _currentFace = widget.diceValue;
    
    // Initialize scale animation for press effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !oldWidget.rolling) {
      _startRolling();
    } else if (!widget.rolling && oldWidget.rolling) {
      _stopRolling();
      setState(() {
        _currentFace = widget.diceValue;
      });
    }
  }

  void _startRolling() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _animationTimer?.cancel();

    // Fast rolling animation
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted) {
        setState(() {
          _currentFace = widget.random.nextInt(6) + 1;
        });
      }
    });

    // Stop rolling after animation duration
    _animationTimer = Timer(const Duration(milliseconds: 1200), () {
      _stopRolling();
      if (mounted) {
        setState(() {
          _currentFace = widget.diceValue;
        });
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _stopRolling() {
    _timer?.cancel();
    _animationTimer?.cancel();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.rolling) {
      setState(() => _isPressed = true);
      _scaleController.forward();
      HapticFeedback.selectionClick();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  void dispose() {
    _stopRolling();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: (widget.enabled && !widget.rolling) ? widget.onRoll : null,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: _getDiceGradient(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _getDiceShadow(),
                border: Border.all(
                  color: widget.enabled ? Colors.white.withOpacity(0.3) : Colors.grey,
                  width: 1,
                ),
              ),
              child: _buildDiceContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiceContent() {
    // Try to load dice image first
    String imageAsset = _getImageAsset();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Background pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
          ),
          
          // Dice face content
          Center(
            child: Image.asset(
              imageAsset,
              width: widget.size * 0.8,
              height: widget.size * 0.8,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackDice();
              },
            ),
          ),
          
          // Rolling animation overlay
          if (widget.rolling)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.transparent,
                    Colors.white.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          
          // Disabled overlay
          if (!widget.enabled)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackDice() {
    return Container(
      width: widget.size * 0.9,
      height: widget.size * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _currentFace != null 
          ? _buildDiceDots(_currentFace!)
          : Icon(
              Icons.casino,
              size: widget.size * 0.5,
              color: Colors.grey[600],
            ),
    );
  }

  Widget _buildDiceDots(int value) {
    return CustomPaint(
      painter: DiceDotsPainter(
        value: value,
        dotColor: Colors.black87,
      ),
      size: Size(widget.size * 0.8, widget.size * 0.8),
    );
  }

  String _getImageAsset() {
    if (_currentFace == null) {
      return 'assets/dice_idle.png';
    } else {
      return 'assets/dice_$_currentFace.png';
    }
  }

  Gradient _getDiceGradient() {
    if (!widget.enabled) {
      return LinearGradient(
        colors: [Colors.grey[600]!, Colors.grey[700]!],
      );
    }
    
    if (widget.rolling) {
      return LinearGradient(
        colors: [Colors.orange[400]!, Colors.orange[600]!],
      );
    }
    
    if (_isPressed) {
      return LinearGradient(
        colors: [Colors.blue[300]!, Colors.blue[400]!],
      );
    }
    
    return LinearGradient(
      colors: [Colors.blue[400]!, Colors.blue[500]!],
    );
  }

  List<BoxShadow> _getDiceShadow() {
    if (!widget.enabled) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
    
    if (_isPressed) {
      return [
        BoxShadow(
          color: Colors.purple.withOpacity(0.4),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    
    return [
      BoxShadow(
        color: Colors.purple.withOpacity(0.6),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

// Custom painter for dice dots when images are not available
class DiceDotsPainter extends CustomPainter {
  final int value;
  final Color dotColor;

  DiceDotsPainter({
    required this.value,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final double dotRadius = size.width * 0.08;
    final double margin = size.width * 0.2;
    
    // Define dot positions
    final positions = _getDotPositions(size, margin);
    
    // Draw dots based on dice value
    final dotPatterns = _getDotPattern(value);
    
    for (int position in dotPatterns) {
      if (position < positions.length) {
        canvas.drawCircle(positions[position], dotRadius, paint);
      }
    }
  }

  List<Offset> _getDotPositions(Size size, double margin) {
    final double third = (size.width - 2 * margin) / 2;
    return [
      Offset(margin, margin),                    // 0: top-left
      Offset(margin + third, margin),            // 1: top-center
      Offset(margin + 2 * third, margin),        // 2: top-right
      Offset(margin, margin + third),            // 3: center-left
      Offset(margin + third, margin + third),    // 4: center
      Offset(margin + 2 * third, margin + third), // 5: center-right
      Offset(margin, margin + 2 * third),        // 6: bottom-left
      Offset(margin + third, margin + 2 * third), // 7: bottom-center
      Offset(margin + 2 * third, margin + 2 * third), // 8: bottom-right
    ];
  }

  List<int> _getDotPattern(int value) {
    switch (value) {
      case 1: return [4]; // center
      case 2: return [0, 8]; // top-left, bottom-right
      case 3: return [0, 4, 8]; // diagonal
      case 4: return [0, 2, 6, 8]; // corners
      case 5: return [0, 2, 4, 6, 8]; // corners + center
      case 6: return [0, 2, 3, 5, 6, 8]; // two columns
      default: return [4];
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is! DiceDotsPainter || 
           oldDelegate.value != value ||
           oldDelegate.dotColor != dotColor;
  }
}

// Enhanced dice widget with additional features
class EnhancedDiceWidget extends StatelessWidget {
  final int? diceValue;
  final bool rolling;
  final VoidCallback onRoll;
  final Random random;
  final bool enabled;
  final String? label;
  final bool showValue;

  const EnhancedDiceWidget({
    Key? key,
    required this.diceValue,
    required this.rolling,
    required this.onRoll,
    required this.random,
    this.enabled = true,
    this.label,
    this.showValue = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        DiceWidget(
          diceValue: diceValue,
          rolling: rolling,
          onRoll: onRoll,
          random: random,
          enabled: enabled,
          size: 70,
        ),
        
        if (showValue && diceValue != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              diceValue.toString(),
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
