import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/game_error_screen.dart';
import '../services/daily_flash_progress_service.dart';
import 'daily_flash_game_screen.dart';

class DailyFlashLoadingScreen extends StatefulWidget {
  final String challengeName;
  final String challengeImagePath;
  final VoidCallback? onChallengeFinished;

  const DailyFlashLoadingScreen({
    super.key,
    this.challengeName = 'PLANETS',
    this.challengeImagePath =
        'assets/images/daily_flash5/planets.png',
    this.onChallengeFinished,
  });

  @override
  State<DailyFlashLoadingScreen> createState() =>
      _DailyFlashLoadingScreenState();
}

class _DailyFlashLoadingScreenState
    extends State<DailyFlashLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;

  late final Animation<double> _pulseAnimation;
  late final Animation<double> _fadeAnimation;

  bool _hasOpenedGame = false;
  bool _hasTechnicalError = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();

    _startLoadingSequence();
  }

  Future<void> _startLoadingSequence() async {
    if (_hasOpenedGame) {
      return;
    }

    if (mounted) {
      setState(() {
        _hasTechnicalError = false;
      });
    }

    try {
      final bool hasSeenLoadingToday =
          await DailyFlashProgressService
              .hasSeenLoadingToday();

      if (!mounted || _hasOpenedGame) {
        return;
      }

      // The splash/loading screen only appears once per day.
      // This remains true even while testingMode allows the
      // Daily Flash itself to be replayed repeatedly.
      if (hasSeenLoadingToday) {
        _openGame();
        return;
      }

      await DailyFlashProgressService
          .markLoadingSeenToday();

      await Future<void>.delayed(
        const Duration(milliseconds: 3000),
      );

      if (!mounted || _hasOpenedGame) {
        return;
      }

      _openGame();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hasTechnicalError = true;
      });
    }
  }

  void _openGame() {
    if (!mounted || _hasOpenedGame) {
      return;
    }

    _hasOpenedGame = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => DailyFlashGameScreen(
          onChallengeFinished: widget.onChallengeFinished,
        ),
      ),
    );
  }

  Future<void> _retryLoading() async {
    await _startLoadingSequence();
  }

  void _backToHome() {
    Navigator.of(context).popUntil(
      (Route<dynamic> route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasTechnicalError) {
      return GameErrorScreen(
        message: 'We couldn’t load this challenge.',
        onTryAgain: _retryLoading,
        onBackToHome: _backToHome,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            final bool isSmall =
                constraints.maxHeight < 720 ||
                constraints.maxWidth < 370;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isSmall ? 2 : 4,
                    isSmall ? 4 : 6,
                    isSmall ? 2 : 4,
                    isSmall ? 6 : 8,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DailyFlashLogo(
                          isSmall: isSmall,
                        ),
                        SizedBox(
                          height: isSmall ? 7 : 9,
                        ),
                        const _ChallengeLabel(),
                        SizedBox(
                          height: isSmall ? 5 : 7,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.challengeName
                                .toUpperCase(),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style:
                                AppTextStyles.category
                                    .copyWith(
                              color: AppColors.white,
                              fontSize:
                                  isSmall ? 40 : 48,
                              fontWeight:
                                  FontWeight.w700,
                              letterSpacing: 1,
                              height: 1,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: isSmall ? 3 : 5,
                        ),
                        _ChallengeArtwork(
                          imagePath:
                              widget.challengeImagePath,
                          pulseAnimation:
                              _pulseAnimation,
                          isSmall: isSmall,
                        ),
                        SizedBox(
                          height: isSmall ? 6 : 8,
                        ),
                        _XpBonusArtwork(
                          isSmall: isSmall,
                        ),
                        SizedBox(
                          height: isSmall ? 5 : 7,
                        ),
                      ],
                    ),
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

class _DailyFlashLogo extends StatelessWidget {
  final bool isSmall;

  const _DailyFlashLogo({
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _LeftOrangeLine(),
        ),
        const SizedBox(width: 8),
        Image.asset(
          'assets/images/daily_flash5/'
          'daily_flash5_logo.png',
          width: isSmall ? 185 : 220,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: _RightOrangeLine(),
        ),
      ],
    );
  }
}

class _ChallengeLabel extends StatelessWidget {
  const _ChallengeLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orange,
          width: 1.3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FE5E02),
            blurRadius: 7,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: AppColors.orange,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            'TODAY\'S CHALLENGE',
            style:
                AppTextStyles.category.copyWith(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.45,
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            Icons.star_rounded,
            color: AppColors.orange,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _ChallengeArtwork extends StatelessWidget {
  final String imagePath;
  final Animation<double> pulseAnimation;
  final bool isSmall;

  const _ChallengeArtwork({
    required this.imagePath,
    required this.pulseAnimation,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final double artworkHeight =
        isSmall ? 215 : 250;

    final double loadingSize =
        isSmall ? 118 : 140;

    return SizedBox(
      height: artworkHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          ScaleTransition(
            scale: pulseAnimation,
            child: SizedBox(
              width: loadingSize,
              height: loadingSize,
              child: Image.asset(
                'assets/images/daily_flash5/'
                'daily_flash_loading.png',
                fit: BoxFit.contain,
                filterQuality:
                    FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpBonusArtwork extends StatelessWidget {
  final bool isSmall;

  const _XpBonusArtwork({
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isSmall ? 340 : 395,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FE5E02),
            blurRadius: 11,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/daily_flash5/'
        'daily_flash_xp_bonus.png',
        width: double.infinity,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _LeftOrangeLine extends StatelessWidget {
  const _LeftOrangeLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.orange,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x55FE5E02),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}

class _RightOrangeLine extends StatelessWidget {
  const _RightOrangeLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange,
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x55FE5E02),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}