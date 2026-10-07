import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MilestonePopupData {
  final int target;
  final String label;
  final int? nextTarget;
  final String? nextLabel;

  const MilestonePopupData({
    required this.target,
    required this.label,
    required this.nextTarget,
    this.nextLabel,
  });
}

class MilestoneReachedDialog extends StatelessWidget {
  final MilestonePopupData milestone;

  const MilestoneReachedDialog({
    super.key,
    required this.milestone,
  });

  static const Color _gold = Color(0xFFD6A83B);
  static const Color _brightGold = Color(0xFFFFD65A);

  String _formatNumber(int value) {
    final String digits = value.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    return value < 0 ? '-$buffer' : buffer.toString();
  }

  String _displayLabel(int target, String label) {
    if (target != 1) {
      return label;
    }

    switch (label.trim().toUpperCase()) {
      case 'ANIMALS':
        return 'ANIMAL';
      case 'COUNTRIES':
        return 'COUNTRY';
      case 'CORRECT ANSWERS':
        return 'CORRECT ANSWER';
      case 'FIRST GUESSES':
        return 'FIRST GUESS';
      case 'DAILY FLASH 5S':
        return 'DAILY FLASH 5';
      case 'FIRST WORD CHALLENGES':
        return 'FIRST WORD CHALLENGE';
      default:
        return label;
    }
  }


  @override
  Widget build(BuildContext context) {
    final int? nextTarget = milestone.nextTarget;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 410,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            16,
            18,
            18,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF11100C),
                Color(0xFF090909),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _brightGold,
              width: 2,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x554D3707),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    const SizedBox(
                      width: double.infinity,
                      height: 58,
                    ),
                    Image.asset(
                      'assets/images/stats/gold_lightning_bolt_badge.png',
                      width: 58,
                      height: 58,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Material(
                        color: AppColors.orange,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 29,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ACHIEVEMENT UNLOCKED!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: _brightGold,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 205,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.30,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _gold,
                      width: 1.6,
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x334F3907),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        _formatNumber(milestone.target),
                        style: const TextStyle(
                          fontFamily: 'Oswald',
                          color: _brightGold,
                          fontSize: 64,
                          height: 0.95,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _displayLabel(
                          milestone.target,
                          milestone.label,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Oswald',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (nextTarget != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _MilestoneInfoCard(
                    assetPath:
                        'assets/images/stats/level_up.png',
                    title: 'NEXT TARGET',
                    value:
                        '${_formatNumber(nextTarget)} ${_displayLabel(
                      nextTarget,
                      milestone.nextLabel ?? milestone.label,
                    )}',
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestoneInfoCard extends StatelessWidget {
  final String assetPath;
  final String title;
  final String value;

  const _MilestoneInfoCard({
    required this.assetPath,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.18,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 46,
            height: 46,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.orange,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeEarnedDialog extends StatelessWidget {
  final String badgeName;
  final String imageAsset;

  const BadgeEarnedDialog({
    super.key,
    required this.badgeName,
    required this.imageAsset,
  });

  static const Color _gold = Color(0xFFD6A83B);
  static const Color _brightGold = Color(0xFFFFD65A);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF11100C),
                Color(0xFF090909),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _brightGold,
              width: 2,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x554D3707),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const SizedBox(
                    width: double.infinity,
                    height: 96,
                  ),
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Material(
                      color: AppColors.orange,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 29,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'BADGE EARNED!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: _brightGold,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _gold,
                    width: 1.6,
                  ),
                ),
                child: Text(
                  badgeName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 210,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.35,
                    ),
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

