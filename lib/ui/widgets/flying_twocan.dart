import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlyingTwocan extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final Offset startPosition;
  final Offset endPosition;
  final bool shouldFly;
  final Duration? duration;
  final Widget? fallbackWidget;

  const FlyingTwocan({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    required this.startPosition,
    required this.endPosition,
    required this.shouldFly,
    this.duration,
    this.fallbackWidget,
  });

  @override
  State<FlyingTwocan> createState() => _FlyingTwocanState();
}

class _FlyingTwocanState extends State<FlyingTwocan>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _arcAnimation;
  late Animation<double> _rotationAnimation;
  
  // Random flight parameters
  double _arcIntensity = 0;
  double _rotationIntensity = 0;
  late Duration _flightDuration;

  @override
  void initState() {
    super.initState();
    _generateRandomFlight();
    _setupAnimations();
  }

  @override
  void didUpdateWidget(FlyingTwocan oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if positions changed or shouldFly changed
    if ((oldWidget.startPosition != widget.startPosition || 
         oldWidget.endPosition != widget.endPosition ||
         oldWidget.shouldFly != widget.shouldFly) && widget.shouldFly) {
      debugPrint('FlyingTwocan: Starting flight from ${widget.startPosition} to ${widget.endPosition}');
      _generateRandomFlight();
      _updateAnimations();
      _startFlight();
    }
  }

  void _generateRandomFlight() {
    final random = math.Random();
    _arcIntensity = 20 + random.nextDouble() * 60; // 20-80px arc
    _rotationIntensity = (random.nextDouble() - 0.5) * 0.4; // -0.2 to 0.2 radians
    _flightDuration = widget.duration ?? Duration(milliseconds: 800 + random.nextInt(400));
    debugPrint('FlyingTwocan: Generated arc=${_arcIntensity.toStringAsFixed(1)}, rotation=${_rotationIntensity.toStringAsFixed(3)}, duration=${_flightDuration.inMilliseconds}ms');
  }

  void _setupAnimations() {
    _controller = AnimationController(duration: _flightDuration, vsync: this);
    _updateAnimations();
  }
  
  void _updateAnimations() {
    // Update controller duration
    _controller.duration = _flightDuration;

    // Main position animation (straight line from start to end)
    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Arc animation (parabolic curve that adds horizontal offset, peaks at middle)
    _arcAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: _ParabolicCurve(_arcIntensity))
    );

    // Rotation animation (banking like a bird, peaks at middle)
    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: _SineCurve(_rotationIntensity))
    );
  }

  void _startFlight() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Use the current position from animation, or final position if not animating
        final position = _controller.isAnimating 
          ? _positionAnimation.value 
          : widget.endPosition;
        final arcOffset = _controller.isAnimating ? _arcAnimation.value : 0.0;
        final rotation = _controller.isAnimating ? _rotationAnimation.value : 0.0;

        return Positioned(
          left: position.dx + arcOffset, // Add arc to the straight-line path
          top: position.dy,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  widget.imagePath,
                  width: widget.width,
                  height: widget.height,
                  errorBuilder: (context, error, stackTrace) {
                    return widget.fallbackWidget ?? Icon(
                      Icons.error,
                      size: math.min(widget.width, widget.height),
                      color: Theme.of(context).colorScheme.error,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom curves for natural bird-like flight
class _ParabolicCurve extends Curve {
  final double maxOffset;
  
  const _ParabolicCurve(this.maxOffset);
  
  @override
  double transformInternal(double t) {
    // Creates a parabolic arc that peaks at t=0.5 and returns to 0 at t=1
    return maxOffset * 4 * t * (1 - t);
  }
}

class _SineCurve extends Curve {
  final double maxRotation;
  
  const _SineCurve(this.maxRotation);
  
  @override
  double transformInternal(double t) {
    // Creates banking rotation that peaks in middle of flight
    return maxRotation * math.sin(t * math.pi);
  }
}