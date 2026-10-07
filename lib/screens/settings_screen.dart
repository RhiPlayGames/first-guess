import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/account_auth_service.dart';
import '../services/avatar_preferences_service.dart';
import '../services/play_games_service.dart';
import '../theme/app_colors.dart';
import 'about_first_guess_screen.dart';
import 'app_version_screen.dart';
import 'delete_account_screen.dart';
import 'privacy_policy_screen.dart';
import 'support_screen.dart';
import 'terms_of_use_screen.dart';
import 'profile_screen.dart';
import 'how_to_play_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _defaultAvatarPath =
      'assets/images/avatars/Final/optimized/default_avatar.webp';

  String _avatarPath = _defaultAvatarPath;
  bool _googleLinked = false;
  bool _accountActionInProgress = false;
  bool _playGamesConnected = false;
  bool _playGamesActionInProgress = false;
  String? _accountEmail;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _loadAccountStatus();
    _loadPlayGamesStatus();
  }

  Future<void> _loadAccountStatus() async {
    try {
      await AccountAuthService.currentUser?.reload();
    } catch (_) {
      // Keep the currently cached account state if refresh is unavailable.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _googleLinked = AccountAuthService.isGoogleLinked;
      _accountEmail = AccountAuthService.email;
    });
  }

  bool get _showPlayGamesOption =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _loadPlayGamesStatus() async {
    if (!_showPlayGamesOption) {
      return;
    }

    final bool connected = await PlayGamesService.isSignedIn;

    if (!mounted) {
      return;
    }

    setState(() {
      _playGamesConnected = connected;
    });
  }

  Future<void> _handlePlayGamesTap() async {
    if (_playGamesActionInProgress || !_showPlayGamesOption) {
      return;
    }

    if (_playGamesConnected) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Google Play Games is connected.'),
          ),
        );
      return;
    }

    setState(() {
      _playGamesActionInProgress = true;
    });

    try {
      final bool connected = await PlayGamesService.signIn();

      if (!mounted) {
        return;
      }

      setState(() {
        _playGamesConnected = connected;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              connected
                  ? 'Google Play Games connected.'
                  : 'Google Play Games was not connected.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _playGamesActionInProgress = false;
        });
      }
    }
  }

  Future<void> _handleAccountTap() async {
    if (_accountActionInProgress) {
      return;
    }

    if (_googleLinked) {
      final bool hasPendingMerge =
          await AccountAuthService.hasPendingGuestProgressMerge();

      if (!mounted) {
        return;
      }

      if (hasPendingMerge) {
        await _retryPendingGuestMerge();
        return;
      }

      final String accountLabel =
          _accountEmail?.isNotEmpty == true
              ? _accountEmail!
              : 'your Google account';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'First Guess is connected to $accountLabel.',
            ),
          ),
        );
      return;
    }

    setState(() {
      _accountActionInProgress = true;
    });

    try {
      final AccountLinkResult result =
          await AccountAuthService.linkCurrentGuestToGoogle();

      if (!mounted) {
        return;
      }

      await _loadAccountStatus();

      if (!mounted) {
        return;
      }

      final String message =
          result.status == AccountLinkStatus.alreadyLinked
              ? 'Google is already connected to this First Guess account.'
              : 'Google connected. Your First Guess progress is now protected.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
    } on AccountAuthException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.code == 'existing-first-guess-account') {
        final bool? recoverExistingAccount =
            await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: AppColors.panel,
              title: const Text(
                'EXISTING ACCOUNT FOUND',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: const Text(
                'This Google account is already connected to an existing '
                'First Guess account.\n\n'
                'Restore that account and merge the guest progress from '
                'this device into it.\n\n'
                'The existing account avatar will be kept.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.white,
                  height: 1.35,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('RESTORE & MERGE'),
                ),
              ],
            );
          },
        );

        if (recoverExistingAccount != true || !mounted) {
          return;
        }

        try {
          final user =
              await AccountAuthService.signInToExistingGoogleAccount();

          if (!mounted) {
            return;
          }

          await _loadAccountStatus();

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  user.email?.isNotEmpty == true
                      ? 'Account restored and guest progress merged: ${user.email}'
                      : 'Account restored and guest progress merged.',
                ),
              ),
            );
        } on AccountAuthException catch (recoveryError) {
          if (!mounted) {
            return;
          }

          if (recoveryError.code == 'guest-merge-pending') {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(recoveryError.message),
                  action: SnackBarAction(
                    label: 'RETRY',
                    onPressed: () {
                      _retryPendingGuestMerge();
                    },
                  ),
                ),
              );
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(recoveryError.message),
              ),
            );
        }

        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _accountActionInProgress = false;
        });
      }
    }
  }

  Future<void> _retryPendingGuestMerge() async {
    if (_accountActionInProgress) {
      return;
    }

    setState(() {
      _accountActionInProgress = true;
    });

    try {
      await AccountAuthService.retryPendingGuestProgressMerge();

      if (!mounted) {
        return;
      }

      await _loadAccountStatus();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Guest progress merged successfully.',
            ),
          ),
        );
    } on AccountAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _accountActionInProgress = false;
        });
      }
    }
  }

  Future<void> _loadAvatar() async {
    final String? savedAvatarPath =
        await AvatarPreferencesService.loadSelectedAvatarPath();

    if (!mounted) {
      return;
    }

    setState(() {
      _avatarPath = savedAvatarPath ?? _defaultAvatarPath;
    });
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProfileScreen(),
      ),
    );

    if (mounted) {
      await _loadAvatar();
    }
  }

  Future<void> _openHowToPlay(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const HowToPlayScreen(),
      ),
    );
  }

  Future<void> _openAbout(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AboutFirstGuessScreen(),
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  Future<void> _openTermsOfUse(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const TermsOfUseScreen(),
      ),
    );
  }

  Future<void> _openSupport(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SupportScreen(),
      ),
    );
  }

  Future<void> _openAppVersion(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AppVersionScreen(),
      ),
    );
  }

  Future<void> _openDeleteAccount(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const DeleteAccountScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          children: [
            _SettingsTile(
              imagePath: _avatarPath,
              title: 'MY PROFILE',
              subtitle: 'Avatar, stats and player information',
              onTap: () => _openProfile(context),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: _googleLinked
                  ? Icons.verified_user_outlined
                  : Icons.account_circle_outlined,
              title: 'ACCOUNT',
              subtitle: _accountActionInProgress
                  ? 'Connecting with Google...'
                  : _googleLinked
                      ? (_accountEmail?.isNotEmpty == true
                          ? 'Connected with Google • $_accountEmail'
                          : 'Connected with Google')
                      : 'Connect with Google to protect progress',
              onTap: _handleAccountTap,
            ),
            const SizedBox(height: 12),
            if (_showPlayGamesOption) ...[
              _SettingsTile(
                icon: _playGamesConnected
                    ? Icons.sports_esports_rounded
                    : Icons.sports_esports_outlined,
                title: 'GOOGLE PLAY GAMES',
                subtitle: _playGamesActionInProgress
                    ? 'Connecting with Google Play Games...'
                    : _playGamesConnected
                        ? 'Google Play Games connected'
                        : 'Connect with Google Play Games',
                onTap: _handlePlayGamesTap,
              ),
              const SizedBox(height: 12),
            ],
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'ABOUT FIRST GUESS',
              subtitle: 'App information',
              onTap: () => _openAbout(context),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              imagePath: 'assets/images/settings/app_version.webp',
              title: 'APP VERSION',
              subtitle: 'Version and build information',
              onTap: () => _openAppVersion(context),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              imagePath: 'assets/images/settings/contact_support.webp',
              title: 'CONTACT SUPPORT',
              subtitle: 'Get help with First Guess',
              onTap: () => _openSupport(context),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'DELETE ACCOUNT',
              subtitle: 'Account deletion',
              onTap: () => _openDeleteAccount(context),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.sports_esports_outlined,
              title: 'HOW TO PLAY',
              subtitle: 'Rules, scoring and Daily Flash 5',
              onTap: () => _openHowToPlay(context),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              imagePath: 'assets/images/settings/privacy_policy.webp',
              title: 'PRIVACY POLICY',
              subtitle: 'How your information is handled',
              onTap: () => _openPrivacyPolicy(context),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              imagePath: 'assets/images/settings/terms_conditions.webp',
              title: 'TERMS OF USE',
              subtitle: 'Terms for using First Guess',
              onTap: () => _openTermsOfUse(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    this.icon,
    this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null || imagePath != null);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: imagePath != null
                    ? const EdgeInsets.all(2)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.orange,
                  ),
                ),
                alignment: Alignment.center,
                child: imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.asset(
                          imagePath!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.orange,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : Icon(
                        icon,
                        color: AppColors.orange,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.orange,
                size: 27,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
