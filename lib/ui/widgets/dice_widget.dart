import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

enum DieType {
  d4(4, 'assets/dice.svg/icons/000000/transparent/1x1/skoll/d4.svg'),
  d6(6, 'assets/dice.svg/icons/000000/transparent/1x1/delapouite/dice-six-faces-six.svg'),
  d8(8, 'assets/dice.svg/icons/000000/transparent/1x1/delapouite/dice-eight-faces-eight.svg'),
  d10(10, 'assets/dice.svg/icons/000000/transparent/1x1/skoll/d10.svg'),
  d12(12, 'assets/dice.svg/icons/000000/transparent/1x1/skoll/d12.svg'),
  d20(20, 'assets/dice.svg/icons/000000/transparent/1x1/delapouite/dice-twenty-faces-twenty.svg');

  const DieType(this.sides, this.assetPath);
  final int sides;
  final String assetPath;
  
  Widget getShapedContainer({
    required Widget child,
    required Color color,
    required Color borderColor,
    double borderWidth = 3,
    List<BoxShadow>? boxShadow,
  }) {
    switch (this) {
      case DieType.d4:
        // Triangular container
        return SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: TrianglePainter(
              color: color,
              borderColor: borderColor,
              borderWidth: borderWidth,
            ),
            child: Center(child: child),
          ),
        );
      
      case DieType.d6:
        // Square container
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: boxShadow,
          ),
          child: Center(child: child),
        );
      
      case DieType.d8:
        // Diamond/octagon container
        return SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: DiamondPainter(
              color: color,
              borderColor: borderColor,
              borderWidth: borderWidth,
            ),
            child: Center(child: child),
          ),
        );
      
      case DieType.d10:
        // Pentagon container
        return SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: PentagonPainter(
              color: color,
              borderColor: borderColor,
              borderWidth: borderWidth,
            ),
            child: Center(child: child),
          ),
        );
      
      case DieType.d12:
      case DieType.d20:
        // Circular container for complex shapes
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: boxShadow,
          ),
          child: Center(child: child),
        );
    }
  }
}

class DiceWidget extends StatefulWidget {
  final bool isRolling;
  final int? result;
  final int optionCount;
  final bool reducedAnimations;

  const DiceWidget({
    super.key,
    this.isRolling = false,
    this.result,
    this.optionCount = 6,
    this.reducedAnimations = false,
  });

  static DieType getDieTypeForOptions(int optionCount) {
    if (optionCount <= 4) return DieType.d4;
    if (optionCount <= 6) return DieType.d6;
    if (optionCount <= 8) return DieType.d8;
    if (optionCount <= 10) return DieType.d10;
    if (optionCount <= 12) return DieType.d12;
    return DieType.d20;
  }

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      if (widget.reducedAnimations) {
        // Very minimal animation for reduced animations mode
        _controller.duration = const Duration(milliseconds: 200);
        _controller.forward();
      } else {
        _controller.repeat();
      }
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dieType = DiceWidget.getDieTypeForOptions(widget.optionCount);
    
    final content = widget.isRolling
        ? AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: widget.reducedAnimations ? 0 : _controller.value * 6.28, // No rotation in reduced animations mode
                child: SvgPicture.asset(
                  dieType.assetPath,
                  width: 56,
                  height: 56,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).filledButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              );
            },
          )
        : widget.result == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    dieType.assetPath,
                    width: 56,
                    height: 56,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).filledButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.optionCount}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).filledButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TAP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: (Theme.of(context).filledButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.white).withValues(alpha: 0.9),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              )
            : Text(
                widget.result.toString(),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).filledButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.white,
                ),
              );

    return dieType.getShapedContainer(
      child: content,
      color: Theme.of(context).colorScheme.primary,
      borderColor: Colors.transparent,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    )
        .animate(target: widget.isRolling ? 1 : 0)
        .scaleXY(begin: 1, end: 1.1, duration: 200.ms)
        .then()
        .scaleXY(begin: 1.1, end: 1, duration: 200.ms);
  }
}

// Custom painters for different die shapes
class TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;

  TrianglePainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - borderWidth;

    // Create triangle
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * 0.866, center.dy + radius * 0.5);
    path.lineTo(center.dx + radius * 0.866, center.dy + radius * 0.5);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiamondPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;

  DiamondPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - borderWidth;

    // Create diamond
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius, center.dy);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius, center.dy);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PentagonPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;

  PentagonPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - borderWidth;

    // Create pentagon
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}