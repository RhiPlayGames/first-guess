import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/feature_flag_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';
import '../services/daily_flash_progress_service.dart';
import '../services/daily_flash_game_progress_service.dart';
import '../services/daily_flash_schedule_service.dart';
import 'daily_flash_first_word_screen.dart';
import 'daily_flash_first_connection_screen.dart';
import 'daily_flash_first_date_screen.dart';
import 'daily_flash_first_match_screen.dart';
import 'daily_flash_first_order_screen.dart';
import 'daily_flash_loading_screen.dart';

class DailyFlashHomeScreen extends StatefulWidget {
  const DailyFlashHomeScreen({super.key});

  @override
  State<DailyFlashHomeScreen> createState() => _DailyFlashHomeScreenState();
}

class _DailyFlashHomeScreenState extends State<DailyFlashHomeScreen> {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  String? _activeDailyFlashDateKey;

  bool _loading = true;
  int _classicProgress = 0;
  int _firstWordProgress = 0;
  int _firstDateProgress = 0;
  int _firstMatchProgress = 0;
  int _firstOrderProgress = 0;
  int _firstConnectionProgress = 0;
  bool _firstConnectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
    _loadProgress();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final bool firstConnectionEnabled =
          await FeatureFlagService.isDailyFlashFirstConnectionEnabled();

      final List<Future<dynamic>> futures = <Future<dynamic>>[
        DailyFlashProgressService.loadToday(),
        DailyFlashGameProgressService.loadToday(
          gameKey: 'first_word',
        ),
        DailyFlashGameProgressService.loadToday(
          gameKey: 'first_date',
        ),
        DailyFlashGameProgressService.loadToday(
          gameKey: 'first_match',
        ),
        DailyFlashGameProgressService.loadToday(
          gameKey: 'first_order',
        ),
        if (firstConnectionEnabled)
          DailyFlashGameProgressService.loadToday(
            gameKey: 'first_connection',
          ),
      ];

      final List<dynamic> results =
          await Future.wait<dynamic>(futures);

      if (!mounted) {
        return;
      }

      final DailyFlashProgress classic =
          results[0] as DailyFlashProgress;
      final DailyFlashGameProgress firstWord =
          results[1] as DailyFlashGameProgress;
      final DailyFlashGameProgress firstDate =
          results[2] as DailyFlashGameProgress;
      final DailyFlashGameProgress firstMatch =
          results[3] as DailyFlashGameProgress;
      final DailyFlashGameProgress firstOrder =
          results[4] as DailyFlashGameProgress;
      final DailyFlashGameProgress? firstConnection =
          firstConnectionEnabled
              ? results[5] as DailyFlashGameProgress
              : null;

      setState(() {
        _classicProgress = classic.nextQuestionIndex.clamp(0, 5);
        _firstWordProgress =
            firstWord.nextQuestionIndex.clamp(0, 5);
        _firstDateProgress =
            firstDate.nextQuestionIndex.clamp(0, 5);
        _firstMatchProgress =
            firstMatch.nextQuestionIndex.clamp(0, 5);
        _firstOrderProgress =
            firstOrder.nextQuestionIndex.clamp(0, 5);
        _firstConnectionProgress =
            firstConnection?.nextQuestionIndex.clamp(0, 5) ?? 0;
        _firstConnectionEnabled = firstConnectionEnabled;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _classicProgress = 0;
        _firstWordProgress = 0;
        _firstDateProgress = 0;
        _firstMatchProgress = 0;
        _firstOrderProgress = 0;
        _firstConnectionProgress = 0;
        _firstConnectionEnabled = false;
        _loading = false;
      });
    }
  }

  Future<void> _openClassicDailyFlash() async {
    if (_classicProgress >= 5) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DailyFlashLoadingScreen(
          onChallengeFinished: _loadProgress,
        ),
      ),
    );

    if (mounted) {
      await _loadProgress();
    }
  }

  Future<void> _openFirstWordDailyFlash() async {
    if (_firstWordProgress >= 5) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DailyFlashFirstWordScreen(
          onChallengeFinished: _loadProgress,
        ),
      ),
    );

    if (mounted) {
      await _loadProgress();
    }
  }

  Future<void> _openFirstDateDailyFlash() async {
    if (_firstDateProgress >= 5) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DailyFlashFirstDateScreen(
          onChallengeFinished: _loadProgress,
        ),
      ),
    );

    if (mounted) {
      await _loadProgress();
    }
  }

  Future<void> _openFirstMatchDailyFlash() async {
    if (_firstMatchProgress >= 5) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DailyFlashFirstMatchScreen(
          onChallengeFinished: _loadProgress,
        ),
      ),
    );

    if (mounted) {
      await _loadProgress();
    }
  }

  Future<void> _openFirstOrderDailyFlash() async {
    if (_firstOrderProgress >= 5) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DailyFlashFirstOrderScreen(
          onChallengeFinished: _loadProgress,
        ),
      ),
    );

    if (mounted) {
      await _loadProgress();
    }
  }

  Future<void> _openFirstConnectionDailyFlash() async {
    if (!_firstConnectionEnabled ||
        _firstConnectionProgress >= 5) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DailyFlashFirstConnectionScreen(
          onChallengeFinished: _loadProgress,
        ),
      ),
    );

    if (mounted) {
      await _loadProgress();
    }
  }

  Future<void> _resetDailyFlashForTesting() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text(
            'RESET DAILY FLASH?',
            style: TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'This resets today’s Daily Flash play progress for testing. '
            'It does not remove lifetime XP, badges or achievements.',
            style: TextStyle(
              color: AppColors.white,
              height: 1.4,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('RESET'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    await DailyFlashProgressService.resetForTesting();
    await DailyFlashGameProgressService.resetAllForTesting();

    if (!mounted) {
      return;
    }

    await _loadProgress();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Daily Flash reset for testing.'),
        ),
      );
  }

  void _showModeComingSoon(String gameName) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.panel,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '$gameName Daily Flash 5 gameplay is being connected.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  void _updateCountdown() {
    final Duration remaining =
        DailyFlashScheduleService.timeUntilNextRelease();
    final String activeDateKey =
        DailyFlashScheduleService.activeDateKey();
    final bool dailyFlashChanged =
        _activeDailyFlashDateKey != null &&
        _activeDailyFlashDateKey != activeDateKey;

    if (!mounted) {
      return;
    }

    setState(() {
      _timeRemaining = remaining;
      _activeDailyFlashDateKey = activeDateKey;
    });

    // If the user leaves this screen open across 16:00 UK time, refresh
    // all progress immediately so the newly released Daily Flash appears.
    if (dailyFlashChanged) {
      unawaited(_loadProgress());
    }
  }

  String get _countdownText {
    final int hours = _timeRemaining.inHours;
    final int minutes = _timeRemaining.inMinutes.remainder(60);
    final int seconds = _timeRemaining.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isDesktop = screenWidth >= 900;
    final double horizontalPadding = isDesktop
        ? ((screenWidth - 1100) / 2).clamp(24.0, double.infinity)
        : 16.0;

    final List<_DailyFlashGameData> games = <_DailyFlashGameData>[
      _DailyFlashGameData(
        title: 'Classic First Guess',
        subtitle: 'Ten clues. One trivia test. Can you find the answer?',
        imagePath:
            'assets/images/categories/classic_firstguess/First Guessicon128.webp',
        progress: _classicProgress,
        enabled: !_loading,
        onPressed: _openClassicDailyFlash,
      ),
      _DailyFlashGameData(
        title: 'First Date',
        subtitle: 'Five events. One date. Can you piece it together?',
        imagePath:
            'assets/images/categories/first_date/firstdateicon128.webp',
        progress: _firstDateProgress,
        enabled: !_loading,
        onPressed: _openFirstDateDailyFlash,
      ),
      _DailyFlashGameData(
        title: 'First Match',
        subtitle: 'Six pairs. Can you complete the perfect board?',
        imagePath:
            'assets/images/categories/first_match/firstmatch_icon128.webp',
        progress: _firstMatchProgress,
        enabled: !_loading,
        onPressed: _openFirstMatchDailyFlash,
      ),
      _DailyFlashGameData(
        title: 'First Order',
        subtitle: 'Five choices. Can you put them in the right order?',
        imagePath:
            'assets/images/categories/first_order/firstorder_icon128.webp',
        progress: _firstOrderProgress,
        enabled: !_loading,
        onPressed: _openFirstOrderDailyFlash,
      ),
      _DailyFlashGameData(
        title: 'First Word',
        subtitle: 'Five clues. One hidden word. How soon can you solve it?',
        imagePath:
            'assets/images/categories/first_word/firstword_128.webp',
        progress: _firstWordProgress,
        enabled: !_loading,
        onPressed: _openFirstWordDailyFlash,
      ),
      _DailyFlashGameData(
        title: 'First Connection',
        subtitle: _firstConnectionEnabled
            ? 'Six clues. One hidden link. Can you find the connection?'
            : 'Six clues. One hidden link. Coming soon.',
        imagePath:
            'assets/images/categories/first_connection/firstconnections_icon128.webp',
        progress: _firstConnectionProgress,
        enabled: !_loading && _firstConnectionEnabled,
        onPressed: _firstConnectionEnabled
            ? _openFirstConnectionDailyFlash
            : () => _showModeComingSoon('First Connection'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FirstGuessHomeButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          backgroundColor: AppColors.panel,
          onRefresh: _loadProgress,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              30,
            ),
            children: [
              _DailyFlashEventHero(
                countdownText: _countdownText,
              ),
              if (kDebugMode) ...<Widget>[
                SizedBox(height: isDesktop ? 12 : 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _loading ? null : _resetDailyFlashForTesting,
                    icon: const Icon(
                      Icons.restart_alt_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'RESET DAILY FLASH',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.orange,
                    ),
                  ),
                ),
              ],
              SizedBox(height: isDesktop ? 20 : 16),
              const _SectionHeading(
                text: 'TODAY\'S CHALLENGES',
              ),
              SizedBox(height: isDesktop ? 16 : 12),
              if (isDesktop)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: games.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 116,
                  ),
                  itemBuilder: (context, index) {
                    return _DailyFlashGameCard(
                      data: games[index],
                      isDesktop: true,
                    );
                  },
                )
              else
                ...games.map(
                  (_DailyFlashGameData game) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DailyFlashGameCard(
                      data: game,
                      isDesktop: false,
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

class _SectionHeading extends StatelessWidget {
  final String text;

  const _SectionHeading({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _HeadingLine()),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Oswald',
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _HeadingLine(reverse: true),
        ),
      ],
    );
  }
}

class _HeadingLine extends StatelessWidget {
  final bool reverse;

  const _HeadingLine({
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: reverse ? Alignment.centerRight : Alignment.centerLeft,
          end: reverse ? Alignment.centerLeft : Alignment.centerRight,
          colors: const <Color>[
            Colors.transparent,
            AppColors.orange,
          ],
        ),
      ),
    );
  }
}

class _DailyFlashGameData {
  final String title;
  final String subtitle;
  final String imagePath;
  final int progress;
  final bool enabled;
  final VoidCallback onPressed;

  const _DailyFlashGameData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.progress,
    required this.enabled,
    required this.onPressed,
  });
}

class _DailyFlashGameCard extends StatelessWidget {
  final _DailyFlashGameData data;
  final bool isDesktop;

  const _DailyFlashGameCard({
    required this.data,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final int progress = data.progress.clamp(0, 5);
    final bool complete = progress >= 5;
    const Color dailyGold = Color(0xFFFFC94A);
    const Color dailyGoldDeep = Color(0xFFD69A19);

    final String ctaText = complete
        ? 'COMPLETE'
        : data.enabled
            ? 'PLAY'
            : 'COMING SOON';

    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 11),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 18),
        border: Border.all(
          color: complete
              ? dailyGold
              : data.enabled
                  ? dailyGoldDeep
                  : AppColors.border,
          width: complete || data.enabled ? 1.35 : 1,
        ),
        boxShadow: complete
            ? <BoxShadow>[
                BoxShadow(
                  color: dailyGold.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: isDesktop ? 64 : 58,
            height: isDesktop ? 64 : 58,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: complete || data.enabled
                    ? dailyGoldDeep
                    : AppColors.darkGrey,
              ),
            ),
            child: Image.asset(
              data.imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.category.copyWith(
                    color: AppColors.white,
                    fontSize: isDesktop ? 17 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: <Widget>[
                    for (int index = 0; index < 5; index++) ...<Widget>[
                      Container(
                        width: isDesktop ? 19 : 17,
                        height: 7,
                        decoration: BoxDecoration(
                          color: index < progress
                              ? dailyGold
                              : const Color(0xFF383838),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      if (index < 4) const SizedBox(width: 4),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '$progress/5',
                      style: AppTextStyles.label.copyWith(
                        color: complete ? dailyGold : AppColors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 9),
          Material(
            color: complete || !data.enabled
                ? AppColors.darkGrey
                : const Color(0xFFE9680B),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: complete ? null : data.onPressed,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: isDesktop ? 106 : 92,
                height: isDesktop ? 38 : 36,
                child: Center(
                  child: Text(
                    ctaText,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: complete
                          ? dailyGold
                          : AppColors.white,
                      fontSize: ctaText == 'COMING SOON' ? 9.5 : 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _DailyFlashEventHero extends StatelessWidget {
  final String countdownText;

  const _DailyFlashEventHero({
    required this.countdownText,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isDesktop = constraints.maxWidth >= 900;

        final String bannerAsset = isDesktop
            ? 'assets/images/daily_flash5/new/dailyflashfive_dailyflash5screen_desktop.webp'
            : 'assets/images/daily_flash5/new/dailyflashfive_dailyflash5screen_mobile.webp';

        final double bannerHeight = isDesktop ? 138 : 64;
        final double radius = isDesktop ? 18 : 14;
        final double timerWidth =
            constraints.maxWidth * (isDesktop ? 0.29 : 0.31);

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: double.infinity,
            height: bannerHeight,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  bannerAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: timerWidth,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 20 : 8,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'ENDS IN',
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                color: AppColors.white,
                                fontSize: isDesktop ? 18 : 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                height: 1.0,
                              ),
                            ),
                            SizedBox(
                              height: isDesktop ? 5 : 2,
                            ),
                            Text(
                              countdownText,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                color: const Color(0xFFFFC94A),
                                fontSize: isDesktop ? 31 : 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

