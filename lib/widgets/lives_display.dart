import 'package:flutter/material.dart';

class LivesDisplay extends StatelessWidget {
  final int lives;
  final int maximumLives;

  const LivesDisplay({
    super.key,
    required this.lives,
    required this.maximumLives,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$lives of $maximumLives lives remaining',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          maximumLives,
          (index) {
            final bool isActive = index < lives;

            return Padding(
              padding: EdgeInsets.only(
                right: index == maximumLives - 1 ? 0 : 2,
              ),
              child: AnimatedOpacity(
                opacity: isActive ? 1.0 : 0.22,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image.asset(
                    'assets/images/stats/life_heart.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}