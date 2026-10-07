import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GuessPanel extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isLastClue;
  final VoidCallback onGuess;
  final VoidCallback onNextClue;
  final VoidCallback onGiveUp;

  const GuessPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isLastClue,
    required this.onGuess,
    required this.onNextClue,
    required this.onGiveUp,
  });

  @override
  State<GuessPanel> createState() => _GuessPanelState();
}

class _GuessPanelState extends State<GuessPanel> {
  void _requestGuessFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.enabled) {
        return;
      }

      widget.focusNode.requestFocus();
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.enabled) {
      _requestGuessFocus();
    }
  }

  @override
  void didUpdateWidget(covariant GuessPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.enabled && widget.enabled) {
      _requestGuessFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Column(
      children: [
        LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            return Transform.translate(
              offset: isDesktop
                  ? Offset.zero
                  : const Offset(-10, 0),
              child: SizedBox(
                width: isDesktop
                    ? constraints.maxWidth
                    : constraints.maxWidth + 20,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.enabled,
                  onSubmitted: (_) {
                    if (widget.enabled) {
                      widget.onGuess();
                    }
                  },
                  textCapitalization:
                      TextCapitalization.words,
                  textInputAction:
                      TextInputAction.done,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.white,
                    fontSize: 17,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type your guess...',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.white,
                      fontSize: 17,
                    ),
                    filled: true,
                    fillColor: AppColors.panel,
                    contentPadding:
                        EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(
                        Radius.circular(16),
                      ),
                      borderSide: BorderSide(
                        color: AppColors.orange,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(
                        Radius.circular(16),
                      ),
                      borderSide: BorderSide(
                        color: AppColors.orange,
                        width: 2,
                      ),
                    ),
                    disabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(
                        Radius.circular(16),
                      ),
                      borderSide: BorderSide(
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: widget.enabled ? widget.onGuess : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.darkGrey,
                    disabledForegroundColor: const Color(0xFF8C8C8C),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'GUESS',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: widget.enabled && !widget.isLastClue ? widget.onNextClue : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    disabledForegroundColor: AppColors.darkGrey,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: BorderSide(
                      color: widget.enabled && !widget.isLastClue
                          ? AppColors.white
                          : AppColors.darkGrey,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'NEXT CLUE',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: widget.enabled ? widget.onGiveUp : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.darkGrey,
              disabledForegroundColor: const Color(0xFF8C8C8C),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'GIVE UP',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
