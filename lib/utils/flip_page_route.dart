import 'package:flutter/material.dart';
import 'dart:math';

class FlipPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FlipPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                // If the animation is entering
                if (animation.status != AnimationStatus.dismissed) {
                  final angle = (1.0 - animation.value) * (pi / 2);
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(-angle),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: animation.value < 0.5 ? 0.0 : 1.0,
                      child: child,
                    ),
                  );
                }
                return child!;
              },
              child: child,
            );
          },
        );
}
