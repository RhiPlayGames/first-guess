import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GameHeader extends StatelessWidget {
  const GameHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Image.asset(
            'assets/images/first_guessV2_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Row(
            children: [
              Text(
                'FIRST',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 7),
              Text(
                'GUESS',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.orange,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.settings,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}