import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';
import 'animal_kingdom_case_path_screen.dart';

class CaseFilesHomeScreen extends StatelessWidget {
  const CaseFilesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CaseFilesHeader(
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 3),
              const _CaseFilesHero(),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CaseFileCard(
                      title: 'ANIMAL KINGDOM',
                      imagePath:
                          'assets/images/case_files/topics/animal_world.webp',
                      status: 'CASE 2 OF 20',
                      imageScale: 1.22,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const AnimalKingdomCasePathScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _CaseFileCard(
                      title: 'AMAZING WORLD',
                      imagePath:
                          'assets/images/case_files/topics/amazing_world.webp',
                      status: 'COMING SOON',
                      imageScale: 1.14,
                      isComingSoon: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CaseFileCard(
                      title: 'MYSTERIES & LEGENDS',
                      imagePath:
                          'assets/images/case_files/topics/mysteries_legends.webp',
                      status: 'COMING SOON',
                      isComingSoon: true,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _CaseFileCard(
                      title: 'TASTES & TREATS',
                      imagePath:
                          'assets/images/case_files/topics/tastes_and_treats.webp',
                      status: 'COMING SOON',
                      isComingSoon: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseFilesHeader extends StatelessWidget {
  final VoidCallback onBackPressed;

  const _CaseFilesHeader({
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBackPressed,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.white,
                size: 26,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 64,
            ),
            child: Image.asset(
              'assets/images/first_guess_header.png',
              height: 52,
              fit: BoxFit.contain,
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: FirstGuessHomeButton(),
          ),
        ],
      ),
    );
  }
}

class _CaseFilesHero extends StatelessWidget {
  const _CaseFilesHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        18,
        12,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD96519),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Image.asset(
              'assets/images/detective_dog.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CASE FILES',
                  maxLines: 1,
                  style: AppTextStyles.category.copyWith(
                    color: AppColors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'EXPLORE. DISCOVER. SOLVE.',
                  maxLines: 1,
                  style: AppTextStyles.label.copyWith(
                    color: const Color(0xFFFE5E02),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.25,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Crack 20 cases, unlock rewards',
                        maxLines: 1,
                        softWrap: false,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'and master each Case File.',
                        maxLines: 1,
                        softWrap: false,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseFileCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final String status;
  final double imageScale;
  final VoidCallback? onTap;
  final bool isComingSoon;

  const _CaseFileCard({
    required this.title,
    required this.imagePath,
    required this.status,
    this.imageScale = 1.0,
    this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isComingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 294,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: isComingSoon ? 0.38 : 1.0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/case_files/topics/case_file_folder.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        8,
                        12,
                        14,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 36,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Image.asset(
                                'assets/images/case_files/topics/top_secret_stamp.png',
                                height: 35,
                                fit: BoxFit.contain,
                                filterQuality:
                                    FilterQuality.high,
                              ),
                            ),
                          ),
                          const SizedBox(height: 0),
                          SizedBox(
                            height: 130,
                            child: Center(
                              child: Transform.rotate(
                                angle: -0.035,
                                child:
                                    FractionallySizedBox(
                                  widthFactor: 0.86,
                                  child: Container(
                                    padding:
                                        const EdgeInsets
                                            .fromLTRB(
                                      6,
                                      6,
                                      6,
                                      15,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: const Color(
                                        0xFFF7F1E6,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(2),
                                      border:
                                          Border.all(
                                        color:
                                            const Color(
                                          0xFFD8C9A9,
                                        ),
                                        width: 0.9,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(
                                            0x66000000,
                                          ),
                                          blurRadius: 6,
                                          offset:
                                              Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      color: const Color(
                                        0xFF171410,
                                      ),
                                      alignment:
                                          Alignment.center,
                                      padding:
                                          const EdgeInsets
                                              .all(2),
                                      child:
                                          Transform.scale(
                                        scale: imageScale,
                                        child: Image.asset(
                                          imagePath,
                                          width: double
                                              .infinity,
                                          height: double
                                              .infinity,
                                          fit:
                                              BoxFit.contain,
                                          filterQuality:
                                              FilterQuality
                                                  .high,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Column(
                            children: [
                              SizedBox(
                                height: 18,
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit
                                        .scaleDown,
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      textAlign:
                                          TextAlign
                                              .center,
                                      style:
                                          AppTextStyles
                                              .category
                                              .copyWith(
                                        color:
                                            AppColors
                                                .white,
                                        fontSize: 15.5,
                                        height: 1,
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                        letterSpacing:
                                            0.05,
                                        shadows: const [
                                          Shadow(
                                            color:
                                                Color(
                                              0xFF2A1708,
                                            ),
                                            blurRadius:
                                                1.2,
                                            offset:
                                                Offset(
                                              -1,
                                              0,
                                            ),
                                          ),
                                          Shadow(
                                            color:
                                                Color(
                                              0xFF2A1708,
                                            ),
                                            blurRadius:
                                                1.2,
                                            offset:
                                                Offset(
                                              1,
                                              0,
                                            ),
                                          ),
                                          Shadow(
                                            color:
                                                Color(
                                              0xFF2A1708,
                                            ),
                                            blurRadius:
                                                1.2,
                                            offset:
                                                Offset(
                                              0,
                                              -1,
                                            ),
                                          ),
                                          Shadow(
                                            color:
                                                Color(
                                              0xFF2A1708,
                                            ),
                                            blurRadius:
                                                1.8,
                                            offset:
                                                Offset(
                                              0,
                                              1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 1,
                              ),
                              SizedBox(
                                height: 13,
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit
                                        .scaleDown,
                                    child: Text(
                                      isComingSoon ? '' : status,
                                      maxLines: 1,
                                      textAlign:
                                          TextAlign
                                              .center,
                                      style:
                                          AppTextStyles
                                              .label
                                              .copyWith(
                                        color:
                                            AppColors
                                                .white,
                                        fontSize: 11.2,
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                        letterSpacing:
                                            0.12,
                                        shadows: const [
                                          Shadow(
                                            color:
                                                Color(
                                              0xFF2A1708,
                                            ),
                                            blurRadius:
                                                1.0,
                                            offset:
                                                Offset(
                                              -0.8,
                                              0,
                                            ),
                                          ),
                                          Shadow(
                                            color:
                                                Color(
                                              0xFF2A1708,
                                            ),
                                            blurRadius:
                                                1.0,
                                            offset:
                                                Offset(
                                              0.8,
                                              0,
                                            ),
                                          ),
                                          Shadow(
                                            color:
                                                Color(
                                              0xFF2A1708,
                                            ),
                                            blurRadius:
                                                1.5,
                                            offset:
                                                Offset(
                                              0,
                                              1,
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
                          const SizedBox(height: 9),
                          if (!isComingSoon)
                            FractionallySizedBox(
                              widthFactor: 0.84,
                              child: _CasePlayButton(
                                onTap: onTap,
                              ),
                            )
                          else
                            const SizedBox(
                              height: 34,
                            ),
                          const SizedBox(height: 6),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
           
              // Large centred padlock for locked Case Files.
              if (isComingSoon)
                Center(
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/case_files/locked_case_padlock.webp',
                      width: 82,
                      height: 82,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
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

class _CasePlayButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _CasePlayButton({
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFA512),
              Color(0xFFFF7900),
              Color(0xFFFE5E02),
            ],
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: const Color(
              0xFFFFA331,
            ),
            width: 1.1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44FE5E02),
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(9),
            child: Center(
              child: Text(
                'PLAY',
                style:
                    AppTextStyles.label.copyWith(
                  color: AppColors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}