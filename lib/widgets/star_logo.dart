import 'package:flutter/material.dart';
import 'dart:math' as math;

class StarLogo extends StatefulWidget {
  final VoidCallback onFlipTriggered;
  
  const StarLogo({Key? key, required this.onFlipTriggered}) : super(key: key);

  @override
  _StarLogoState createState() => _StarLogoState();
}

class _StarLogoState extends State<StarLogo> with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  bool _isAnimatingSequence = false;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 4.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.1).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_scaleController);

    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFlipTriggered();
        _scaleController.reset();
        _isAnimatingSequence = false;
        _orbitController.repeat();
      }
    });
  }

  void _triggerSequence() {
    if (_isAnimatingSequence) return;
    _isAnimatingSequence = true;
    _orbitController.stop();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerSequence,
      child: AnimatedBuilder(
        animation: Listenable.merge([_orbitController, _scaleController]),
        builder: (context, child) {
          final double orbitAngle = _orbitController.value * 2 * math.pi;
          final double dx = math.cos(orbitAngle) * (_isAnimatingSequence ? 0 : 25.0);
          final double dy = math.sin(orbitAngle) * (_isAnimatingSequence ? 0 : 25.0);

          return Container(
            width: 150,
            height: 150,
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scale: _isAnimatingSequence ? _scaleAnimation.value : 1.0,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.amberAccent, blurRadius: 30, spreadRadius: 5)
                    ]
                  ),
                  child: const Icon(
                    Icons.star_rounded, 
                    size: 80, 
                    color: Colors.amberAccent
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
