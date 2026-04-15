import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

enum ToastType { success, error, warning, info }

class AppToast {
  AppToast._();

  static void show(
    String message, {
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlayContext = Get.overlayContext;
    if (overlayContext == null) return;
    final overlay = Overlay.of(overlayContext);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    // Post-frame to avoid overlay insertion during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlay.insert(entry);
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _typeColor {
    switch (widget.type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.error:
        return AppColors.danger;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.info:
        return AppColors.primary;
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.center,
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final hasTitle = widget.title != null && widget.title!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: _typeColor, width: 4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_typeIcon, color: _typeColor, size: 26),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTitle) ...[
                    Text(
                      widget.title!,
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: hasTitle ? 13 : 14,
                      fontWeight:
                          hasTitle ? FontWeight.w400 : FontWeight.w600,
                      color: hasTitle
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
