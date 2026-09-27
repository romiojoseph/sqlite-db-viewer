import 'app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class CopyButton extends StatefulWidget {
  final String textToCopy;
  final String tooltip;
  final double iconSize;

  const CopyButton({
    super.key,
    required this.textToCopy,
    this.tooltip = 'Copy to clipboard',
    this.iconSize = 16.0,
  });

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  void _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    if (!mounted) return;
    setState(() {
      _copied = true;
    });
    await Future.delayed(AppDurations.normal * 4);
    if (!mounted) return;
    setState(() {
      _copied = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _copied ? 'Copied!' : widget.tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(4.0),
        onTap: _handleCopy,
        child: Padding(
          padding: AppSpacing.paddingXxs,
          child: AnimatedSwitcher(
            duration: AppDurations.fast,
            child: _copied
                ? AppSvgIcon(
                    AppIcons.checkCircle,
                    key: const ValueKey('check'),
                    size: widget.iconSize,
                    color: AppColors.success,
                  )
                : AppSvgIcon(
                    AppIcons.copy,
                    key: const ValueKey('copy'),
                    size: widget.iconSize,
                    color: AppColors.neutral8,
                  ),
          ),
        ),
      ),
    );
  }
}
