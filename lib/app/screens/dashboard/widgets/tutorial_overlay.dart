import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../modules/dashboard/dashboard_controller.dart';

class TutorialOverlay extends StatelessWidget {
  final TutorialController controller;
  const TutorialOverlay({super.key, required this.controller});

  static final _targetKeys = [
    DashboardController.statsKey,
    DashboardController.quickActionsKey,
    DashboardController.recentInvoicesKey,
    DashboardController.fabKey,
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.currentStep.value;
      if (step < 0 || step >= TutorialController.steps.length) {
        return const SizedBox.shrink();
      }

      final tutorialStep = TutorialController.steps[step];
      final key = _targetKeys[step];

      // Get target widget position
      Rect? targetRect;
      final renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        targetRect = Rect.fromLTWH(
          offset.dx - 8,
          offset.dy - 8,
          renderBox.size.width + 16,
          renderBox.size.height + 16,
        );
      }

      return GestureDetector(
        onTap: controller.nextStep,
        child: Stack(
          children: [
            // Dimmed overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(targetRect: targetRect),
              ),
            ),

            // Tooltip card
            if (targetRect != null)
              Positioned(
                left: 16,
                right: 16,
                top: targetRect.bottom + 16 < MediaQuery.of(context).size.height - 180
                    ? targetRect.bottom + 16
                    : targetRect.top - 180,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded,
                                color: AppColors.warning, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tutorialStep.title,
                                style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tutorialStep.description,
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${step + 1}/${TutorialController.steps.length}',
                              style: const TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: controller.completeTutorial,
                                  child: const Text('Skip'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: controller.nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    step ==
                                            TutorialController.steps.length - 1
                                        ? 'Done'
                                        : 'Next',
                                    style: const TextStyle(
                                      fontFamily: 'NotoSans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  _SpotlightPainter({this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);

    if (targetRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(targetRect!, const Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.targetRect != targetRect;
}
