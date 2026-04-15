import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../modules/dashboard/dashboard_controller.dart';
import '../../routes/app_routes.dart';
import '../invoices/widgets/status_chip.dart';
// import 'widgets/gemini_chat_sheet.dart'; // AI chatbot — disabled
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
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: Obx(() {
              final name = c.userProfile.value?.googleDisplayName ?? 'User';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.greeting,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              );
            }),
            actions: [
              Obx(() {
                final photoUrl = c.userProfile.value?.googlePhotoUrl;
                final name = c.userProfile.value?.googleDisplayName ?? 'U';
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
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

                  // ── Stats Row ───────────────────────────────────────────
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
                              gradientColors: AppColors.cardGradientRed,
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Quick Actions ────────────────────────────────────────
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
                            childAspectRatio: 1.35,
                            children: [
                              _QuickActionCard(
                                icon: Icons.receipt_long_rounded,
                                label: 'New Invoice',
                                iconBgColor: AppColors.primary,
                                onTap: () =>
                                    Get.toNamed(AppRoutes.createInvoice),
                              ),
                              _QuickActionCard(
                                icon: Icons.person_add_alt_1_rounded,
                                label: 'Add Client',
                                iconBgColor: AppColors.accent,
                                onTap: () => Get.toNamed(AppRoutes.addClient),
                              ),
                              _QuickActionCard(
                                icon: Icons.list_alt_rounded,
                                label: 'All Invoices',
                                iconBgColor: AppColors.success,
                                onTap: () {
                                  try {
                                    final shell =
                                        Get.find<dynamic>(tag: 'shell');
                                    shell?.changePage(2);
                                  } catch (_) {
                                    Get.toNamed(AppRoutes.invoiceList);
                                  }
                                },
                              ),
                              _QuickActionCard(
                                icon: Icons.bar_chart_rounded,
                                label: 'Reports',
                                iconBgColor: const Color(0xFFF9AB00),
                                onTap: () => Get.toNamed(AppRoutes.reports),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Recent Invoices ──────────────────────────────────────
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
                              onPressed: () =>
                                  Get.toNamed(AppRoutes.invoiceList),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
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
                                      clientName: c.clientName(inv.clientId),
                                      date: DateFormatter.formatLong(
                                          inv.invoiceDate),
                                      amount:
                                          CurrencyFormatter.format(inv.total),
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

          // // ── Extended AI FAB (disabled — re-enable with Gemini chatbot) ──
          // floatingActionButton: FloatingActionButton.extended(
          //   key: DashboardController.fabKey,
          //   onPressed: () => showModalBottomSheet(
          //     context: context,
          //     isScrollControlled: true,
          //     backgroundColor: Colors.transparent,
          //     builder: (_) => const GeminiChatSheet(),
          //   ),
          //   backgroundColor: AppColors.primary,
          //   elevation: 4,
          //   icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          //   label: const Text(
          //     'Ask AI',
          //     style: TextStyle(
          //       fontFamily: 'NotoSans',
          //       color: Colors.white,
          //       fontWeight: FontWeight.w700,
          //       fontSize: 14,
          //     ),
          //   ),
          // ),
        ),

        // ── Tutorial Overlay ────────────────────────────────────────────────
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}

// ── Quick Action Card (vertical: icon above label) ────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconBgColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
                      clientName,
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
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'No invoices yet',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
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
