import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../modules/reports/reports_controller.dart';

class ReportsScreen extends GetView<ReportsController> {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Overview Cards ─────────────────────────────────────────────
            Obx(() => Row(
                  children: [
                    _OverviewCard(
                      label: 'TOTAL INVOICED',
                      value: CurrencyFormatter.compact(
                          controller.totalInvoiced.value),
                      icon: Icons.receipt_long_rounded,
                      gradientColors: AppColors.cardGradientBlue,
                    ),
                    const SizedBox(width: 12),
                    _OverviewCard(
                      label: 'TOTAL COLLECTED',
                      value: CurrencyFormatter.compact(
                          controller.totalCollected.value),
                      icon: Icons.check_circle_outline_rounded,
                      gradientColors: AppColors.cardGradientGreen,
                    ),
                  ],
                )),

            const SizedBox(height: 20),

            // ── Invoice Health ─────────────────────────────────────────────
            _SectionHeader(title: 'Invoice Health'),
            const SizedBox(height: 12),
            Obx(() {
              final counts = controller.statusCounts;
              final total = counts.values.fold(0, (a, b) => a + b);
              if (total == 0) {
                return const _EmptyCard();
              }
              return _SectionCard(
                child: Column(
                  children: [
                    // Stacked horizontal progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 12,
                        child: Row(
                          children: [
                            _ProgressSegment(
                                flex: counts['paid'] ?? 0,
                                total: total,
                                color: AppColors.success),
                            _ProgressSegment(
                                flex: counts['sent'] ?? 0,
                                total: total,
                                color: AppColors.primary),
                            _ProgressSegment(
                                flex: counts['draft'] ?? 0,
                                total: total,
                                color: AppColors.statusDraft),
                            _ProgressSegment(
                                flex: counts['overdue'] ?? 0,
                                total: total,
                                color: AppColors.danger),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    _LegendRow(
                        label: 'Paid',
                        count: counts['paid'] ?? 0,
                        total: total,
                        color: AppColors.success),
                    const SizedBox(height: 8),
                    _LegendRow(
                        label: 'Sent',
                        count: counts['sent'] ?? 0,
                        total: total,
                        color: AppColors.primary),
                    const SizedBox(height: 8),
                    _LegendRow(
                        label: 'Draft',
                        count: counts['draft'] ?? 0,
                        total: total,
                        color: AppColors.statusDraft),
                    const SizedBox(height: 8),
                    _LegendRow(
                        label: 'Overdue',
                        count: counts['overdue'] ?? 0,
                        total: total,
                        color: AppColors.danger),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // ── Monthly Revenue ────────────────────────────────────────────
            _SectionHeader(title: 'Revenue Growth'),
            const SizedBox(height: 4),
            Text(
              'Last 6 months performance',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final monthly = controller.monthlyRevenue;
              if (monthly.values.every((v) => v == 0)) {
                return const _EmptyCard(
                    message: 'No paid invoices in the last 6 months');
              }
              final maxVal =
                  monthly.values.reduce((a, b) => a > b ? a : b);
              return _SectionCard(
                child: SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: monthly.entries.map((e) {
                      final frac = maxVal > 0 ? e.value / maxVal : 0.0;
                      final month = e.key.split('-')[1];
                      return _GradientBarColumn(
                        label: _monthLabel(month),
                        fraction: frac,
                        value: e.value,
                      );
                    }).toList(),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // ── Top Clients ────────────────────────────────────────────────
            Obx(() {
              if (controller.topClients.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Key Partners'),
                  const SizedBox(height: 12),
                  _SectionCard(
                    child: Column(
                      children: [
                        ...controller.topClients
                            .asMap()
                            .entries
                            .map((e) => _ClientRevenueRow(
                                  rank: e.key + 1,
                                  name: e.value.name,
                                  revenue: e.value.revenue,
                                  isLast: e.key ==
                                      controller.topClients.length - 1,
                                )),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View All Clients',
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Export Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export Yearly Audit',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Download your complete invoice report for the current fiscal year',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _ExportButton(
                              icon: Icons.download_rounded,
                              label: 'Download PDF',
                              onTap: () {},
                            ),
                            const SizedBox(width: 10),
                            _ExportButton(
                              icon: Icons.table_chart_outlined,
                              label: 'Export CSV',
                              onTap: () {},
                              outlined: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _monthLabel(String m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final idx = (int.tryParse(m) ?? 1) - 1;
    return months[idx.clamp(0, 11)];
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 10,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final int flex;
  final int total;
  final Color color;
  const _ProgressSegment(
      {required this.flex, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    if (flex == 0 || total == 0) return const SizedBox.shrink();
    return Expanded(
      flex: flex,
      child: Container(color: color),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _LegendRow(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
        Text('$count',
            style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text('$pct%',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 12,
                  color: theme.colorScheme.outline)),
        ),
      ],
    );
  }
}

class _GradientBarColumn extends StatelessWidget {
  final String label;
  final double fraction;
  final double value;
  const _GradientBarColumn(
      {required this.label, required this.fraction, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (value > 0)
          Text(
            CurrencyFormatter.compact(value),
            style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 9,
                color: theme.colorScheme.outline),
          ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: 30,
          height: (fraction * 110).clamp(4.0, 110.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ClientRevenueRow extends StatelessWidget {
  final int rank;
  final String name;
  final double revenue;
  final bool isLast;
  const _ClientRevenueRow(
      {required this.rank,
      required this.name,
      required this.revenue,
      required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFBBC04).withOpacity(0.2)
                  : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$rank',
                  style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: rank == 1
                          ? const Color(0xFFF9AB00)
                          : AppColors.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(name,
                  style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface))),
          Text(
            CurrencyFormatter.format(revenue),
            style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              outlined ? Colors.transparent : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: outlined
              ? Border.all(color: Colors.white.withOpacity(0.6))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String? message;
  const _EmptyCard({this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message ?? 'No data available yet',
          style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              color: theme.colorScheme.outline),
        ),
      ),
    );
  }
}
