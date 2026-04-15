import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../modules/invoices/invoice_controller.dart';
import '../../routes/app_routes.dart';
import 'widgets/status_chip.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<InvoiceListController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Obx(() => c.isSearching.value
            ? TextField(
                controller: c.searchController,
                autofocus: true,
                onChanged: (v) => c.searchQuery.value = v,
                decoration: const InputDecoration(
                  hintText: 'Search invoices...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textHint),
                ),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 16),
              )
            : const Text(
                'Invoices',
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              )),
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                    c.isSearching.value ? Icons.close : Icons.search_rounded,
                    color: AppColors.textPrimary),
                onPressed: c.toggleSearch,
              )),
        ],
      ),
      body: Column(
        children: [
          // ── Stats Banner ────────────────────────────────────────────────
          Obx(() {
            final allInvoices = c.invoices;
            final outstanding = allInvoices
                .where((i) => i.status != 'paid')
                .fold(0.0, (sum, i) => sum + i.balanceDue);
            final now = DateTime.now();
            final thisMonth = allInvoices
                .where((i) =>
                    i.status == 'paid' &&
                    i.invoiceDate.year == now.year &&
                    i.invoiceDate.month == now.month)
                .fold(0.0, (sum, i) => sum + i.paymentMade);
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${allInvoices.where((i) => i.status != 'paid').length} invoices pending',
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'TOTAL OUTSTANDING',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(outstanding),
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '${allInvoices.where((i) => i.status == 'paid').length} Invoices Settled',
                              style: const TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COLLECTED THIS MONTH',
                            style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 10,
                              color: AppColors.textHint,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.compact(thisMonth),
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // ── Filter Chips ────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: Obx(() => SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    children: InvoiceListController.statuses.map((s) {
                      final isSelected = c.selectedStatus.value == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => c.setStatus(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              s[0].toUpperCase() + s.substring(1),
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )),
          ),

          const SizedBox(height: 8),

          // ── Invoice List ────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (c.filteredInvoices.isEmpty) {
                return _EmptyInvoices(
                  hasFilter: c.selectedStatus.value != 'all' ||
                      c.searchQuery.value.isNotEmpty,
                  onCreate: c.goToCreate,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: c.filteredInvoices.length,
                itemBuilder: (_, i) {
                  final inv = c.filteredInvoices[i];
                  return Dismissible(
                    key: Key(inv.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white),
                    ),
                    confirmDismiss: (_) async => await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Delete Invoice',
                            style: TextStyle(fontFamily: 'NotoSans')),
                        content: Text(
                            'Delete ${inv.invoiceNumber}? This cannot be undone.',
                            style: const TextStyle(fontFamily: 'NotoSans')),
                        actions: [
                          TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text('Delete',
                                  style:
                                      TextStyle(color: AppColors.danger))),
                        ],
                      ),
                    ),
                    onDismissed: (_) => c.deleteInvoice(inv.id),
                    child: GestureDetector(
                      onTap: () => c.goToPreview(inv),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt_rounded,
                                  color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(inv.invoiceNumber,
                                      style: const TextStyle(
                                        fontFamily: 'NotoSans',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      )),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.clientName(inv.clientId),
                                    style: const TextStyle(
                                      fontFamily: 'NotoSans',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.formatLong(inv.invoiceDate),
                                    style: const TextStyle(
                                      fontFamily: 'NotoSans',
                                      fontSize: 11,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(inv.total),
                                  style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusChip(status: inv.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.toNamed(AppRoutes.createInvoice);
          c.loadInvoices();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Invoice',
            style: TextStyle(
                fontFamily: 'NotoSans',
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _EmptyInvoices extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onCreate;
  const _EmptyInvoices({required this.hasFilter, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? 'No invoices found' : 'No invoices yet',
              style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try a different filter or search'
                  : 'Create your first invoice to get started',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 14,
                  color: AppColors.textSecondary),
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create Invoice'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
