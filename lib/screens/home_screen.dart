import 'dart:async';

import 'package:flutter/material.dart';

import '../daily_flash/screens/daily_flash_home_screen.dart';
import '../daily_flash/services/daily_flash_schedule_service.dart';
import '../services/avatar_preferences_service.dart';
import '../services/feature_flag_service.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/stats_panel.dart';
import '../widgets/subcategory_status_badge.dart';
import 'classic_first_guess_screen.dart';
import 'first_connection_game_screen.dart';
import 'first_date_game_screen.dart';
import 'first_match_game_screen.dart';
import 'first_order_game_screen.dart';
import 'first_word_game_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedAvatarPath;

  PlayerStats _playerStats = const PlayerStats();
  bool _statsLoaded = false;
  bool _firstConnectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedAvatar();
    _loadPlayerStats();
    _loadFeatureFlags();
  }

  Future<void> _loadFeatureFlags() async {
    final bool firstConnectionEnabled =
        await FeatureFlagService.isFirstConnectionEnabled();

    if (!mounted) {
      return;
    }

    setState(() {
      _firstConnectionEnabled = firstConnectionEnabled;
    });
  }

  Future<void> _loadPlayerStats() async {
    final PlayerStats savedStats = await PlayerStatsService.loadStats();

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = savedStats;
      _statsLoaded = true;
    });
  }

  Future<void> _loadSelectedAvatar() async {
    final String? selectedAvatarPath =
        await AvatarPreferencesService.loadSelectedAvatarPath();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAvatarPath = selectedAvatarPath;
    });
  }

  Future<void> _openClassicFirstGuess() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ClassicFirstGuessScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openFirstConnection() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FirstConnectionGameScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openFirstDate() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FirstDateGameScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openFirstMatch() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FirstMatchGameScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openFirstOrder() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FirstOrderGameScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openFirstWord() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FirstWordGameScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openDailyFlashHub() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const DailyFlashHomeScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProfileScreen(),
      ),
    );

    await Future.wait([
      _loadSelectedAvatar(),
      _loadPlayerStats(),
    ]);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SettingsScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await Future.wait([
      _loadSelectedAvatar(),
      _loadPlayerStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1200;

    final List<_CategoryData> modes = <_CategoryData>[
      _CategoryData(
        title: 'Classic First Guess',
        subtitle: 'Ten clues. One trivia test. Can you find the answer?',
        imagePath:
            'assets/images/categories/classic_firstguess/First Guessicon128.webp',
        isAvailable: true,
        onPressed: _openClassicFirstGuess,
        ctaLabel: 'PLAY',
      ),
      _CategoryData(
        title: 'First Date',
        subtitle: 'Five events. One date. Can you piece it together?',
        imagePath:
            'assets/images/categories/first_date/firstdateicon128.webp',
        isAvailable: true,
        onPressed: _openFirstDate,
        ctaLabel: 'PLAY',
      ),
      _CategoryData(
        title: 'First Match',
        subtitle: 'Six pairs. One perfect board. Can you match them all?',
        imagePath:
            'assets/images/categories/first_match/firstmatch_icon128.webp',
        isAvailable: true,
        onPressed: _openFirstMatch,
        ctaLabel: 'PLAY',
      ),
      _CategoryData(
        title: 'First Order',
        subtitle: 'Five choices. One correct order. Can you rank them all?',
        imagePath:
            'assets/images/categories/first_order/firstorder_icon128.webp',
        isAvailable: true,
        onPressed: _openFirstOrder,
        ctaLabel: 'PLAY',
      ),
      _CategoryData(
        title: 'First Word',
        subtitle: 'Five clues. One hidden word. How soon can you uncover it?',
        imagePath:
            'assets/images/categories/first_word/firstword_128.webp',
        isAvailable: true,
        onPressed: _openFirstWord,
        ctaLabel: 'PLAY',
      ),
      _CategoryData(
        title: 'First Connection',
        subtitle: 'Six clues. One hidden link. Can you find the connection?',
        imagePath:
            'assets/images/categories/first_connection/firstconnections_icon128.webp',
        isAvailable: _firstConnectionEnabled,
        onPressed: _openFirstConnection,
        ctaLabel: 'PLAY',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 16,
            14,
            isDesktop ? 24 : 16,
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1360 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeHeader(
                    onProfilePressed: () => _openProfile(context),
                    onSettingsPressed: _openSettings,
                    selectedAvatarPath: _selectedAvatarPath,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: isDesktop ? 6 : 0,
                      bottom: isDesktop ? 18 : 10,
                    ),
                    child: StatsPanel(
                      totalScore:
                          _statsLoaded ? _playerStats.totalScore : 0,
                      currentStreak:
                          _statsLoaded ? _playerStats.currentStreak : 0,
                      firstGuesses:
                          _statsLoaded ? _playerStats.firstGuesses : 0,
                      gamesPlayed:
                          _statsLoaded ? _playerStats.gamesPlayed : 0,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 6 : 8),
                  _DailyFlashHomeBanner(
                    onPressed: _openDailyFlashHub,
                  ),
                  SizedBox(height: isDesktop ? 18 : 14),
                  const _ChallengeHeading(),
                  SizedBox(height: isDesktop ? 12 : 10),
                  if (!isDesktop)
                    Column(
                      children: modes
                          .map(
                            (_CategoryData mode) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: _CategoryCard(
                                category: mode,
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: modes.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 96,
                      ),
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        return _CategoryCard(
                          category: modes[index],
                        );
                      },
                    ),
                  SizedBox(height: isDesktop ? 16 : 4),
                  const _AdSpace(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onProfilePressed;
  final VoidCallback onSettingsPressed;
  final String? selectedAvatarPath;

  const _HomeHeader({
    required this.onProfilePressed,
    required this.onSettingsPressed,
    required this.selectedAvatarPath,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isNarrow = constraints.maxWidth < 390;
        final bool isDesktop = constraints.maxWidth >= 1200;

        final double logoWidth = isNarrow ? 58 : 68;
        final double logoHeight = isNarrow ? 66 : 76;
        final double titleHeight = isNarrow ? 48 : 56;
        final double headerHeight =
            isDesktop ? 104 : (isNarrow ? 78 : 88);
        final double avatarSize =
            isDesktop ? 72 : (isNarrow ? 40 : 44);
        final double settingsSize =
            isDesktop ? 72 : (isNarrow ? 38 : 42);

        return SizedBox(
          height: headerHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 72 : 84,
                  ),
                  child: Image.asset(
                    'assets/images/first_guess_header.png',
                    height: titleHeight,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: logoWidth,
                  height: logoHeight,
                  child: Image.asset(
                    'assets/images/first_guess_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onProfilePressed,
                        borderRadius:
                            BorderRadius.circular(12),
                        child: SizedBox(
                          width: avatarSize,
                          height: avatarSize,
                          child: Image.asset(
                            selectedAvatarPath ??
                                'assets/images/avatars/Final/optimized/default_avatar.webp',
                            fit: BoxFit.contain,
                            filterQuality:
                                FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isDesktop ? 16 : 14,
                    ),
                    Tooltip(
                      message: 'Settings',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onSettingsPressed,
                          borderRadius:
                              BorderRadius.circular(
                            settingsSize / 2,
                          ),
                          child: SizedBox(
                            width: settingsSize,
                            height: settingsSize,
                            child: Icon(
                              Icons.settings_rounded,
                              color:
                                  const Color(0xFFB8BCC2),
                              size: settingsSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DailyFlashHomeBanner extends StatefulWidget {
  final VoidCallback onPressed;

  const _DailyFlashHomeBanner({
    required this.onPressed,
  });

  @override
  State<_DailyFlashHomeBanner> createState() =>
      _DailyFlashHomeBannerState();
}

class _DailyFlashHomeBannerState
    extends State<_DailyFlashHomeBanner> {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final Duration remaining =
        DailyFlashScheduleService.timeUntilNextRelease();

    if (!mounted) {
      return;
    }

    setState(() {
      _timeRemaining =
          remaining.isNegative ? Duration.zero : remaining;
    });
  }

  String get _countdownText {
    final int hours = _timeRemaining.inHours;
    final int minutes =
        _timeRemaining.inMinutes.remainder(60);
    final int seconds =
        _timeRemaining.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isDesktop = constraints.maxWidth >= 900;

        final String bannerAsset = isDesktop
            ? 'assets/images/daily_flash5/new/dailyflashfive_homescreen_desktop.webp'
            : 'assets/images/daily_flash5/new/dailyflashfive_homescreen_mobile.webp';

        final double bannerHeight = isDesktop ? 132 : 56;
        final double radius = isDesktop ? 18 : 14;
        final double timerWidth =
            constraints.maxWidth * (isDesktop ? 0.25 : 0.27);

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
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
                          horizontal: isDesktop ? 18 : 6,
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
                                  fontSize: isDesktop ? 18 : 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  height: 1.0,
                                ),
                              ),
                              SizedBox(
                                height: isDesktop ? 5 : 2,
                              ),
                              Text(
                                _countdownText,
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: 'Oswald',
                                  color: const Color(0xFFFFC94A),
                                  fontSize: isDesktop ? 31 : 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
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
          ),
        );
      },
    );
  }
}

class _ChallengeHeading extends StatelessWidget {
  const _ChallengeHeading();

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Row(
      children: [
        const Expanded(
          child: _ChallengeLine(),
        ),
        SizedBox(
          width: isDesktop ? 16 : 10,
        ),
        Text(
          'CHOOSE YOUR GAME',
          textAlign: TextAlign.center,
          style: AppTextStyles.category.copyWith(
            color: AppColors.white,
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(
          width: isDesktop ? 16 : 10,
        ),
        const Expanded(
          child: _ChallengeLine(
            reverse: true,
          ),
        ),
      ],
    );
  }
}

class _ChallengeLine extends StatelessWidget {
  final bool reverse;

  const _ChallengeLine({
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: reverse
              ? Alignment.centerRight
              : Alignment.centerLeft,
          end: reverse
              ? Alignment.centerLeft
              : Alignment.centerRight,
          colors: const [
            Colors.transparent,
            AppColors.orange,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FE5E02),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isAvailable;
  final VoidCallback? onPressed;
  final String ctaLabel;

  const _CategoryData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.ctaLabel,
    this.onPressed,
    this.isAvailable = false,
  });
}

class _CategoryCard extends StatelessWidget {
  final _CategoryData category;

  const _CategoryCard({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable =
        category.isAvailable;

    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    final double radius =
        isDesktop ? 16 : 22;

    return AnimatedOpacity(
      duration:
          const Duration(milliseconds: 200),
      opacity: isAvailable ? 1 : 0.52,
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(radius),
        child: InkWell(
          onTap: isAvailable
              ? category.onPressed
              : null,
          borderRadius:
              BorderRadius.circular(radius),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius:
                  BorderRadius.circular(radius),
              border: Border.all(
                color: isAvailable
                    ? AppColors.orange
                    : AppColors.darkGrey,
                width:
                    isAvailable ? 1.8 : 1.2,
              ),
              boxShadow: isAvailable
                  ? const [
                      BoxShadow(
                        color:
                            Color(0x2BFE5E02),
                        blurRadius: 12,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    isDesktop ? 12 : 14,
                vertical:
                    isDesktop ? 10 : 14,
              ),
              child: Row(
                children: [
                  Container(
                    width:
                        isDesktop ? 58 : 60,
                    height:
                        isDesktop ? 58 : 60,
                    alignment:
                        Alignment.center,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.background,
                      borderRadius:
                          BorderRadius.circular(
                        isDesktop ? 14 : 17,
                      ),
                      border:
                          Border.all(
                        color: isAvailable
                            ? AppColors.orange
                            : AppColors.darkGrey,
                        width: 1.4,
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        4,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          isDesktop ? 10 : 13,
                        ),
                        child: Image.asset(
                          category.imagePath,
                          fit: BoxFit.contain,
                          filterQuality:
                              FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width:
                        isDesktop ? 12 : 15,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title
                              .toUpperCase(),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              AppTextStyles.category
                                  .copyWith(
                            color: isAvailable
                                ? AppColors.white
                                : AppColors.grey,
                            fontSize:
                                isDesktop
                                    ? 20
                                    : 17,
                            letterSpacing:
                                0.15,
                          ),
                        ),
                        if (category
                            .subtitle.isNotEmpty) ...[
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            category.subtitle,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                AppTextStyles.body
                                    .copyWith(
                              color: isAvailable
                                  ? AppColors.white
                                  : AppColors.grey,
                              fontSize:
                                  isDesktop
                                      ? 15.5
                                      : 13.5,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width:
                        isDesktop ? 12 : 10,
                  ),
                  if (isDesktop)
                    _DesktopCategoryCta(
                      text:
                          category.ctaLabel,
                      isAvailable:
                          isAvailable,
                    )
                  else if (isAvailable)
                    _AvailableCategoryStatus(
                      text:
                          category.ctaLabel,
                    )
                  else
                    const _LockedCategoryStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopCategoryCta
    extends StatelessWidget {
  final String text;
  final bool isAvailable;

  const _DesktopCategoryCta({
    required this.text,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted =
        text == 'COMPLETED';

    return Container(
      width: 118,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isAvailable
            ? (
                isCompleted
                    ? AppColors.darkGrey
                    : AppColors.orange
              )
            : AppColors.background,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable
              ? (
                  isCompleted
                      ? AppColors.darkGrey
                      : AppColors.orange
                )
              : AppColors.darkGrey,
          width: 1.2,
        ),
      ),
      child: Text(
        isAvailable ? text : 'COMING SOON',
        maxLines: 1,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.label.copyWith(
          color: isAvailable
              ? AppColors.white
              : AppColors.grey,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _AvailableCategoryStatus
    extends StatelessWidget {
  const _AvailableCategoryStatus({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted =
        text == 'COMPLETED';

    return SubcategoryStatusBadge(
      text: text,
      color: isCompleted
          ? AppColors.darkGrey
          : AppColors.orange,
      filled: true,
      compact: true,
    );
  }
}

class _LockedCategoryStatus
    extends StatelessWidget {
  const _LockedCategoryStatus();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_rounded,
            color: AppColors.grey,
            size: 21,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.orange,
                width: 1,
              ),
            ),
            child: Text(
              'COMING SOON',
              textAlign: TextAlign.center,
              maxLines: 1,
              style:
                  AppTextStyles.label.copyWith(
                color: AppColors.grey,
                fontSize: 8,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdSpace extends StatelessWidget {
  const _AdSpace();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Text(
        'ADVERTISEMENT',
        style: AppTextStyles.label.copyWith(
          color: AppColors.grey,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}