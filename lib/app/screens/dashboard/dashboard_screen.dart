import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../modules/dashboard/dashboard_controller.dart';
import '../../routes/app_routes.dart';
import '../invoices/widgets/status_chip.dart';
import 'widgets/gemini_chat_sheet.dart';
import 'widgets/tutorial_overlay.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DashboardController>();
    final tutorial = Get.find<TutorialController>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: Obx(() => Text(
                  c.greeting,
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                )),
            actions: [
              Obx(() {
                final photoUrl = c.userProfile.value?.googlePhotoUrl;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            (c.userProfile.value?.googleDisplayName
                                        ?.isNotEmpty ==
                                    true
                                ? c.userProfile.value!.googleDisplayName![0]
                                : 'U'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => c.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Stats Row ─────────────────────────────────────────────
                  SizedBox(
                    key: DashboardController.statsKey,
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Obx(() => _StatCard(
                              label: 'Total Revenue',
                              value: CurrencyFormatter.compact(
                                  c.totalRevenue.value),
                              icon: Icons.currency_rupee_rounded,
                              gradientColors: AppColors.cardGradientBlue,
                            )),
                        const SizedBox(width: 12),
                        Obx(() => _StatCard(
                              label: 'Clients',
                              value: c.totalClients.value.toString(),
                              icon: Icons.people_rounded,
                              gradientColors: AppColors.cardGradientTeal,
                            )),
                        const SizedBox(width: 12),
                        Obx(() => _StatCard(
                              label: 'Pending',
                              value: CurrencyFormatter.compact(
                                  c.pendingAmount.value),
                              icon: Icons.hourglass_bottom_rounded,
                              gradientColors: AppColors.cardGradientOrange,
                            )),
                        const SizedBox(width: 12),
                        Obx(() => _StatCard(
                              label: 'Overdue',
                              value: c.overdueCount.value.toString(),
                              icon: Icons.warning_amber_rounded,
                              gradientColors: [
                                AppColors.danger,
                                const Color(0xFFC62828),
                              ],
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Quick Actions ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          key: DashboardController.quickActionsKey,
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.6,
                            children: [
                              _QuickActionCard(
                                icon: Icons.add_circle_outline_rounded,
                                label: 'New Invoice',
                                color: AppColors.primary,
                                onTap: () =>
                                    Get.toNamed(AppRoutes.createInvoice),
                              ),
                              _QuickActionCard(
                                icon: Icons.person_add_alt_1_rounded,
                                label: 'Add Client',
                                color: AppColors.accent,
                                onTap: () => Get.toNamed(AppRoutes.addClient),
                              ),
                              _QuickActionCard(
                                icon: Icons.receipt_long_rounded,
                                label: 'All Invoices',
                                color: const Color(0xFF34A853),
                                onTap: () {
                                  final shell =
                                      Get.find<dynamic>(tag: 'shell');
                                  shell?.changePage(2);
                                },
                              ),
                              _QuickActionCard(
                                icon: Icons.bar_chart_rounded,
                                label: 'Reports',
                                color: const Color(0xFFF9AB00),
                                onTap: () => Get.toNamed(AppRoutes.reports),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Recent Invoices ────────────────────────────────────────
                  Padding(
                    key: DashboardController.recentInvoicesKey,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Invoices',
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.toNamed(AppRoutes.invoiceList),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          if (c.recentInvoices.isEmpty) {
                            return _EmptyInvoices();
                          }
                          return Column(
                            children: c.recentInvoices
                                .map((inv) => _RecentInvoiceTile(
                                      invoiceNumber: inv.invoiceNumber,
                                      clientName:
                                          c.clientName(inv.clientId),
                                      date: DateFormatter.formatLong(
                                          inv.invoiceDate),
                                      amount: CurrencyFormatter.format(
                                          inv.total),
                                      status: inv.status,
                                      onTap: () => Get.toNamed(
                                          AppRoutes.invoicePreview,
                                          arguments: inv),
                                    ))
                                .toList(),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Gemini FAB ────────────────────────────────────────────────────
          floatingActionButton: FloatingActionButton(
            key: DashboardController.fabKey,
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const GeminiChatSheet(),
            ),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white),
          ),
        ),

        // ── Tutorial Overlay ──────────────────────────────────────────────
        Obx(() => tutorial.isVisible.value
            ? TutorialOverlay(controller: tutorial)
            : const SizedBox.shrink()),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 11,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

// ── Recent Invoice Tile ───────────────────────────────────────────────────────
class _RecentInvoiceTile extends StatelessWidget {
  final String invoiceNumber;
  final String clientName;
  final String date;
  final String amount;
  final String status;
  final VoidCallback onTap;

  const _RecentInvoiceTile({
    required this.invoiceNumber,
    required this.clientName,
    required this.date,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoiceNumber,
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$clientName • $date',
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusChip(status: status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInvoices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text(
            'No invoices yet',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create your first invoice to get started',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
