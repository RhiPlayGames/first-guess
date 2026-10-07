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
    'assets/images/avatars/Final/optimized/default_avatar.webp',
    'assets/images/avatars/Final/optimized/04_hedgehog.webp',
    'assets/images/avatars/Final/optimized/05_pig.webp',
    'assets/images/avatars/Final/optimized/06_hippo.webp',
    'assets/images/avatars/Final/optimized/07_otter.webp',
    'assets/images/avatars/Final/optimized/08_parrot.webp',
    'assets/images/avatars/Final/optimized/09_octopus.webp',
    'assets/images/avatars/Final/optimized/10_black_white_cat.webp',
    'assets/images/avatars/Final/optimized/11_light_brown_dog.webp',
    'assets/images/avatars/Final/optimized/12_zebra.webp',
    'assets/images/avatars/Final/optimized/13_panda.webp',
    'assets/images/avatars/Final/optimized/14_elephant.webp',
    'assets/images/avatars/Final/optimized/15_fox.webp',
    'assets/images/avatars/Final/optimized/16_giraffe.webp',
    'assets/images/avatars/Final/optimized/18_unicorn.webp',
    'assets/images/avatars/Final/optimized/21_astronaut.webp',
    'assets/images/avatars/Final/optimized/owl.webp',
    'assets/images/avatars/Final/optimized/alien.webp',
    'assets/images/avatars/Final/optimized/wizard.webp',
    'assets/images/avatars/Final/optimized/female_explorer.webp',
    'assets/images/avatars/Final/optimized/knight.webp',
    'assets/images/avatars/Final/optimized/pirate.webp',
    'assets/images/avatars/Final/optimized/raccoon_blocky.webp',
    'assets/images/avatars/Final/optimized/scientist.webp',
    'assets/images/avatars/Final/optimized/bookworm.webp',
    'assets/images/avatars/Final/optimized/detectivedog.webp',
    'assets/images/avatars/Final/optimized/ghost.webp',
    'assets/images/avatars/Final/optimized/jigsaw.webp',
    'assets/images/avatars/Final/optimized/penguin.webp',
    'assets/images/avatars/Final/optimized/robot.webp',
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
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

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
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1080 : double.infinity,
                  ),
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 8 : 16,
                      0,
                      isDesktop ? 8 : 16,
                      16,
                    ),
                    itemCount: _avatarPaths.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 6 : 3,
                      crossAxisSpacing: isDesktop ? 14 : 12,
                      mainAxisSpacing: isDesktop ? 14 : 12,
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
          const Spacer(),
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