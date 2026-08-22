import 'package:flutter/material.dart';

import '../services/avatar_preferences_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_home_button.dart';

class AvatarPickerScreen extends StatefulWidget {
  final String? initialAvatarPath;

  const AvatarPickerScreen({
    super.key,
    this.initialAvatarPath,
  });

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  static const List<String> _avatarPaths = <String>[
    'assets/images/avatars/01_default.webp',
    'assets/images/avatars/02_detective_dog.webp',
    'assets/images/avatars/03_cool_cat.webp',
    'assets/images/avatars/04_fox.webp',
    'assets/images/avatars/05_panda.webp',
    'assets/images/avatars/06_robot.webp',
    'assets/images/avatars/07_astronaut.webp',
    'assets/images/avatars/08_ninja.webp',
    'assets/images/avatars/09_owl.webp',
    'assets/images/avatars/10_lion.webp',
    'assets/images/avatars/11_penguin.webp',
    'assets/images/avatars/12_dragon.webp',
    'assets/images/avatars/13_knight.webp',
    'assets/images/avatars/14_pirate.webp',
    'assets/images/avatars/15_unicorn.webp',
    'assets/images/avatars/16_wolf.webp',
    'assets/images/avatars/17_bear.webp',
    'assets/images/avatars/18_tiger.webp',
    'assets/images/avatars/19_shark.webp',
    'assets/images/avatars/20_alien.webp',
    'assets/images/avatars/21_eagle.webp',
    'assets/images/avatars/22_koala.webp',
    'assets/images/avatars/23_hedgehog.webp',
    'assets/images/avatars/24_rabbit.webp',
    'assets/images/avatars/25_raccoon.webp',
    'assets/images/avatars/26_sloth.webp',
    'assets/images/avatars/27_chameleon.webp',
    'assets/images/avatars/28_frog.webp',
    'assets/images/avatars/29_zebra.webp',
    'assets/images/avatars/30_giraffe.webp',
    'assets/images/avatars/31_cow.webp',
    'assets/images/avatars/32_pig.webp',
    'assets/images/avatars/33_horse.webp',
    'assets/images/avatars/34_elephant.webp',
    'assets/images/avatars/35_monkey.webp',
    'assets/images/avatars/36_fox_girl.webp',
    'assets/images/avatars/37_cat_hoodie.webp',
    'assets/images/avatars/38_husky.webp',
    'assets/images/avatars/39_cheetah.webp',
    'assets/images/avatars/40_hippo.webp',
    'assets/images/avatars/41_dinosaur.webp',
    'assets/images/avatars/42_phoenix.webp',
    'assets/images/avatars/43_octopus.webp',
    'assets/images/avatars/44_owl_wizard.webp',
    'assets/images/avatars/45_wizard.webp',
    'assets/images/avatars/46_cyborg.webp',
    'assets/images/avatars/47_steampunk.webp',
    'assets/images/avatars/48_viking.webp',
    'assets/images/avatars/49_samurai.webp',
    'assets/images/avatars/50_ace_pilot.webp',
    'assets/images/avatars/51_otter.webp',
  ];

  int _selectedIndex = 0;

  String get _selectedAvatarPath => _avatarPaths[_selectedIndex];

  @override
  void initState() {
    super.initState();

    final String? initialAvatarPath = widget.initialAvatarPath;
    if (initialAvatarPath != null) {
      final int initialIndex = _avatarPaths.indexOf(initialAvatarPath);
      if (initialIndex >= 0) {
        _selectedIndex = initialIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  _buildCurrentAvatar(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _avatarPaths.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _AvatarTile(
                    imagePath: _avatarPaths[index],
                    isSelected: index == _selectedIndex,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.orange,
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.white,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'CHOOSE YOUR AVATAR',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: AppTextStyles.category.copyWith(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const FirstGuessHomeButton(),
        ],
      ),
    );
  }

  Widget _buildCurrentAvatar() {
    return SizedBox(
      width: 126,
      height: 126,
      child: Image.asset(
        _selectedAvatarPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () async {
                await AvatarPreferencesService.saveSelectedAvatarPath(
                  _selectedAvatarPath,
                );

                if (!context.mounted) {
                  return;
                }

                Navigator.of(context).pop(_selectedAvatarPath);
              },
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.orange,
                    width: 1.3,
                  ),
                ),
                child: Text(
                  'SAVE AVATAR',
                  style: AppTextStyles.category.copyWith(
                    color: AppColors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _AvatarTile extends StatelessWidget {
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFB21A)
                  : AppColors.orange.withValues(alpha: 0.75),
              width: isSelected ? 3 : 1.4,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x88FE5E02),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              if (isSelected)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: 19,
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