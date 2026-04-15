import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../modules/invoices/invoice_controller.dart';
import '../../routes/app_routes.dart';

class InvoiceDetailsScreen extends GetView<InvoiceDetailsController> {
  const InvoiceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Edit Invoice',
            onPressed: () async {
              final inv = controller.invoice.value;
              if (inv == null) return;
              await Get.toNamed(AppRoutes.editInvoice, arguments: inv);
              controller.refreshInvoice();
            },
          ),
        ],
      ),
      body: Obx(() {
        final inv = controller.invoice.value;
        final client = controller.client.value;
        if (inv == null || client == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final isPaid = inv.status == 'paid';
        final paymentCount = inv.paymentMade > 0 ? 1 : 0;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Status Header ────────────────────────────────────────────
              Container(
                color: AppColors.successLight,
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isPaid ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPaid
                            ? Icons.check_rounded
                            : Icons.access_time_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isPaid
                          ? 'You got fully paid!'
                          : inv.status == 'sent'
                              ? 'Invoice Sent'
                              : inv.status == 'overdue'
                                  ? 'Payment Overdue'
                                  : 'Draft Invoice',
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(inv.total),
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Client Card ──────────────────────────────────────────────
              _DetailCard(
                child: InkWell(
                  onTap: () => Get.toNamed(
                    AppRoutes.clientDetail,
                    arguments: client,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            client.initials,
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            client.name,
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Payments Card ────────────────────────────────────────────
              _DetailCard(
                child: InkWell(
                  onTap: () => _showPaymentDetails(context, inv),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$paymentCount Payment${paymentCount == 1 ? '' : 's'} Received',
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Invoice Meta Card ────────────────────────────────────────
              _DetailCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _MetaRow(
                        label: 'Due on',
                        value: DateFormatter.formatFull(inv.dueDate),
                      ),
                      const SizedBox(height: 8),
                      _MetaRow(label: 'Terms', value: inv.terms),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Invoice#:',
                                  style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  inv.invoiceNumber,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Invoice Date:',
                                  style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatter.formatFull(inv.invoiceDate),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Items Card ───────────────────────────────────────────────
              _DetailCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items (${inv.items.length})',
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...inv.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.description,
                                        style: const TextStyle(
                                          fontFamily: 'NotoSans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} × ${CurrencyFormatter.format(item.rate)}',
                                        style: const TextStyle(
                                          fontFamily: 'NotoSans',
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.amount),
                                  style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Sub Total + VIEW PDF ─────────────────────────────────────
              _DetailCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Text(
                        'Sub Total',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Obx(() => controller.isGeneratingPdf.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : OutlinedButton.icon(
                              onPressed: controller.viewPdf,
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: const Text(
                                'VIEW PDF',
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.primary, width: 1.2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      }),

      // ── Bottom Action Bar ──────────────────────────────────────────────────
      bottomNavigationBar: Obx(() {
        final inv = controller.invoice.value;
        if (inv == null) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border:
                Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              // Share Invoice Link — wide button
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.shareInvoiceLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Share Invoice Link',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Download
              _BottomIconBtn(
                icon: Icons.download_rounded,
                tooltip: 'Download PDF',
                onTap: controller.downloadPdf,
              ),
              const SizedBox(width: 4),
              // WhatsApp
              _BottomIconBtn(
                icon: Icons.chat_rounded,
                tooltip: 'Share on WhatsApp',
                onTap: controller.shareWhatsApp,
                color: const Color(0xFF25D366),
              ),
              const SizedBox(width: 4),
              // More options
              _BottomIconBtn(
                icon: Icons.more_horiz_rounded,
                tooltip: 'More options',
                onTap: () => _showMoreOptions(context, inv),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showPaymentDetails(BuildContext context, dynamic inv) {
    if (inv.paymentMade <= 0) {
      AppToast.show('No payments have been received for this invoice.', title: 'No Payments', type: ToastType.warning);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Received',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount Paid',
                  style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 14,
                      color: AppColors.textSecondary),
                ),
                Text(
                  CurrencyFormatter.format(inv.paymentMade as double),
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, dynamic inv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inv.status != 'paid')
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success),
                title: const Text('Mark as Paid',
                    style: TextStyle(fontFamily: 'NotoSans')),
                onTap: () {
                  Get.back();
                  controller.markAsPaid();
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: const Text('Edit Invoice',
                  style: TextStyle(fontFamily: 'NotoSans')),
              onTap: () async {
                Get.back();
                await Get.toNamed(AppRoutes.editInvoice,
                    arguments: inv);
                controller.refreshInvoice();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.textSecondary),
              title: const Text('View PDF',
                  style: TextStyle(fontFamily: 'NotoSans')),
              onTap: () {
                Get.back();
                controller.viewPdf();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;
  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:  ',
          style: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const _BottomIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color ?? AppColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
