import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_home_button.dart';

class InviteMembersScreen extends StatelessWidget {
  const InviteMembersScreen({
    super.key,
    required this.leagueName,
    required this.badgePath,
    required this.memberCount,
  });

  final String leagueName;
  final String badgePath;
  final int memberCount;

  static const Color _orange = Color(0xFFFE5E02);
  static const Color _background = Color(0xFF050505);
  static const Color _panel = Color(0xFF111111);
  static const Color _panelLight = Color(0xFF181818);
  static const Color _border = Color(0xFF343434);

  String get _inviteCode {
    final String cleaned = leagueName
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');

    final String prefix = cleaned.isEmpty
        ? 'LEAGUE'
        : (cleaned.length > 7 ? cleaned.substring(0, 7) : cleaned);

    return '${prefix}24';
  }

  String get _inviteLink =>
      'https://rhiplaygames.github.io/first-guess/join/$_inviteCode';

  Future<void> _copyText(
    BuildContext context,
    String value,
    String message,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: value),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF111111),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareInvite(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF111111),
        content: Text(
          'Native sharing will be connected later.',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  28,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    _buildLeagueCard(),
                    const SizedBox(height: 22),
                    _buildSectionTitle(
                      number: 1,
                      title: 'INVITE CODE',
                    ),
                    const SizedBox(height: 10),
                    _buildCodeCard(context),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      number: 2,
                      title: 'INVITE LINK',
                    ),
                    const SizedBox(height: 10),
                    _buildLinkCard(context),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      number: 3,
                      title: 'SHARE INVITE',
                    ),
                    const SizedBox(height: 10),
                    _buildShareButton(context),
                    const SizedBox(height: 18),
                    _buildInfoPanel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        4,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'INVITE MEMBERS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const FirstGuessHomeButton(),
        ],
      ),
    );
  }

  Widget _buildLeagueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Image.asset(
              badgePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'LEAGUE',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      color: _orange,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$memberCount MEMBERS',
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildSectionTitle({
    required int number,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _orange,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Oswald',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeCard(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _inviteCode,
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SmallActionButton(
            icon: Icons.copy_rounded,
            label: 'COPY',
            onPressed: () {
              _copyText(
                context,
                _inviteCode,
                'Invite code copied.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.link_rounded,
            color: _orange,
            size: 23,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _inviteLink,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SmallActionButton(
            icon: Icons.copy_rounded,
            label: 'COPY',
            onPressed: () {
              _copyText(
                context,
                _inviteLink,
                'Invite link copied.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(
    BuildContext context,
  ) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          _shareInvite(context);
        },
        icon: const Icon(
          Icons.ios_share_rounded,
          size: 21,
        ),
        label: const Text(
          'SHARE INVITE',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: const Color(0x55FE5E02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Oswald',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.35,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_rounded,
            color: _orange,
            size: 21,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Only players with your invite code or invite link can join this private league. Real codes and links will be generated when Firebase is connected.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(
          color: Color(0xFFFE5E02),
          width: 1.3,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Oswald',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
