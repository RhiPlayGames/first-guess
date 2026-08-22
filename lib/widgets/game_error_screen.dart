import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GameErrorScreen extends StatefulWidget {
  final String message;
  final Future<void> Function() onTryAgain;
  final VoidCallback onBackToHome;

  const GameErrorScreen({
    super.key,
    this.message = 'We couldn’t load this challenge.',
    required this.onTryAgain,
    required this.onBackToHome,
  });

  @override
  State<GameErrorScreen> createState() =>
      _GameErrorScreenState();
}

class _GameErrorScreenState
    extends State<GameErrorScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) {
      return;
    }

    setState(() {
      _retrying = true;
    });

    try {
      await widget.onTryAgain();
    } catch (_) {
      // The parent keeps the error screen visible if retry fails.
    } finally {
      if (mounted) {
        setState(() {
          _retrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  24,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.orange,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(
                        alpha: 0.16,
                      ),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.orange,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.priority_high_rounded,
                        color: AppColors.orange,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'OOPS!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        color: AppColors.orange,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'SOMETHING WENT WRONG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1.2,
                            color: AppColors.orange,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor:
                                AppColors.orange,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1.2,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        color: AppColors.orange,
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.orange,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF35C46A),
                            size: 52,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'YOUR PROGRESS IS SAFE.',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    color: AppColors.white,
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'No points, lives or streaks were lost.\n'
                                  'You can try again in a moment.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.white,
                                    fontSize: 15.5,
                                    fontWeight:
                                        FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed:
                            _retrying ? null : _retry,
                        icon: _retrying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                size: 29,
                              ),
                        label: Text(
                          _retrying
                              ? 'TRYING AGAIN...'
                              : 'TRY AGAIN',
                          style: const TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              AppColors.orange,
                          foregroundColor:
                              AppColors.white,
                          disabledBackgroundColor:
                              AppColors.orange
                                  .withValues(alpha: 0.55),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(17),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: widget.onBackToHome,
                        icon: const Icon(
                          Icons.home_rounded,
                          color: AppColors.orange,
                          size: 27,
                        ),
                        label: const Text(
                          'BACK TO HOME',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.orange,
                            width: 1.6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(17),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
