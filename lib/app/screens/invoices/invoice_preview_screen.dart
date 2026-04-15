import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/number_to_words.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/services/email_service.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/pdf_service.dart';
import '../../modules/invoices/invoice_controller.dart';
import '../../routes/app_routes.dart';
import 'widgets/status_chip.dart';

class InvoicePreviewScreen extends GetView<InvoicePreviewController> {
  const InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() =>
            Text(controller.invoice.value?.invoiceNumber ?? 'Invoice')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final inv = controller.invoice.value;
              if (inv == null) return;
              await Get.toNamed(AppRoutes.editInvoice, arguments: inv);
              controller.onInit();
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
        final profile = HiveService.getProfile() ??
            UserProfileModel(businessName: 'My Business', email: '');

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            children: [
              // Invoice document card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Business + TAX INVOICE header ──────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.businessName,
                                style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (profile.address.isNotEmpty)
                                Text(profile.address,
                                    style: const TextStyle(
                                        fontFamily: 'NotoSans',
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              if (profile.email.isNotEmpty)
                                Text(profile.email,
                                    style: const TextStyle(
                                        fontFamily: 'NotoSans',
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              if (profile.gstin != null)
                                Text('GSTIN: ${profile.gstin}',
                                    style: const TextStyle(
                                        fontFamily: 'NotoSans',
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'TAX INVOICE',
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StatusChip(status: inv.status),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // ── Invoice meta ────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _MetaSection(rows: [
                            _MetaRow('Invoice #', inv.invoiceNumber),
                            _MetaRow('Invoice Date',
                                DateFormatter.format(inv.invoiceDate)),
                            _MetaRow('Terms', inv.terms),
                          ]),
                        ),
                        Expanded(
                          child: _MetaSection(rows: [
                            _MetaRow('Due Date',
                                DateFormatter.format(inv.dueDate)),
                          ]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // ── Bill To ─────────────────────────────────────────────
                    const Text('Bill To',
                        style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(client.name,
                        style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    if (client.address.isNotEmpty)
                      Text(client.address,
                          style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    if (client.email.isNotEmpty)
                      Text(client.email,
                          style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    if (client.gstin != null)
                      Text('GSTIN: ${client.gstin}',
                          style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 11,
                              color: AppColors.textSecondary)),

                    const SizedBox(height: 16),

                    // ── Items table ─────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.border, width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                    width: 24,
                                    child: Text('#',
                                        style: _headerStyle)),
                                Expanded(
                                    flex: 4,
                                    child: Text('Item & Description',
                                        style: _headerStyle)),
                                SizedBox(
                                    width: 40,
                                    child: Text('Qty',
                                        textAlign: TextAlign.center,
                                        style: _headerStyle)),
                                SizedBox(
                                    width: 52,
                                    child: Text('Rate',
                                        textAlign: TextAlign.right,
                                        style: _headerStyle)),
                                SizedBox(
                                    width: 64,
                                    child: Text('Amount',
                                        textAlign: TextAlign.right,
                                        style: _headerStyle)),
                              ],
                            ),
                          ),
                          // Rows
                          ...inv.items.asMap().entries.map((e) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: AppColors.border,
                                        width: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                        width: 24,
                                        child: Text('${e.key + 1}',
                                            style: _cellStyle)),
                                    Expanded(
                                        flex: 4,
                                        child: Text(e.value.description,
                                            style: _cellStyle)),
                                    SizedBox(
                                        width: 40,
                                        child: Text(
                                            e.value.quantity
                                                .toStringAsFixed(2),
                                            textAlign: TextAlign.center,
                                            style: _cellStyle)),
                                    SizedBox(
                                        width: 52,
                                        child: Text(
                                            CurrencyFormatter.formatNoSymbol(
                                                e.value.rate),
                                            textAlign: TextAlign.right,
                                            style: _cellStyle)),
                                    SizedBox(
                                        width: 64,
                                        child: Text(
                                            CurrencyFormatter.formatNoSymbol(
                                                e.value.amount),
                                            textAlign: TextAlign.right,
                                            style: _cellStyle)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Total in words ──────────────────────────────────────
                    Text(
                      NumberToWords.toWords(inv.total),
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    if (inv.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Notes: ${inv.notes}',
                          style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // ── Totals ──────────────────────────────────────────────
                    _TotalRow('Sub Total',
                        CurrencyFormatter.format(inv.subTotal)),
                    if (inv.applyGst) ...[
                      if (!inv.isInterState) ...[
                        _TotalRow(
                            'CGST (${inv.gstPercent / 2}%)',
                            CurrencyFormatter.format(inv.cgstAmount)),
                        _TotalRow(
                            'SGST (${inv.gstPercent / 2}%)',
                            CurrencyFormatter.format(inv.sgstAmount)),
                      ] else
                        _TotalRow(
                            'IGST (${inv.gstPercent}%)',
                            CurrencyFormatter.format(inv.igstAmount)),
                    ],
                    const Divider(height: 12),
                    _TotalRow('Total',
                        CurrencyFormatter.format(inv.total),
                        isBold: true),
                    if (inv.paymentMade > 0)
                      _TotalRow(
                          'Payment Made',
                          '(-) ${CurrencyFormatter.format(inv.paymentMade)}'),
                    _TotalRow(
                      'Balance Due',
                      CurrencyFormatter.format(inv.balanceDue),
                      isBold: true,
                      color: inv.balanceDue <= 0
                          ? AppColors.success
                          : AppColors.primary,
                    ),

                    const SizedBox(height: 16),

                    // ── Signature ───────────────────────────────────────────
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 24),
                          SizedBox(
                            width: 100,
                            child: Divider(thickness: 0.8),
                          ),
                          Text('Authorized Signature',
                              style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border:
                Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary action
              GestureDetector(
                onTap: () => _generateAndOpenPdf(context, inv),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf_outlined,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Generate PDF',
                          style: TextStyle(
                              fontFamily: 'NotoSans',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Secondary actions row
              Row(
                children: [
                  _ActionBtn(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () => _sharePdf(context, inv),
                  ),
                  _ActionBtn(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    onTap: () => _sendEmail(context, inv),
                  ),
                  if (inv.status != 'paid')
                    _ActionBtn(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Mark Paid',
                      color: AppColors.success,
                      onTap: controller.markAsPaid,
                    ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _generateAndOpenPdf(
      BuildContext context, InvoiceModel inv) async {
    try {
      AppToast.show('Creating PDF...', type: ToastType.info,
          duration: const Duration(seconds: 1));
      final client = HiveService.getClient(inv.clientId);
      final profile = HiveService.getProfile() ??
          UserProfileModel(businessName: 'My Business', email: '');
      if (client == null) return;
      final file = await PdfService.generateInvoicePdf(
        invoice: inv,
        client: client,
        business: profile,
      );
      final Uint8List bytes = await file.readAsBytes();
      await Get.toNamed(
        AppRoutes.pdfViewer,
        arguments: {'bytes': bytes, 'title': inv.invoiceNumber},
      );
    } catch (e) {
      AppToast.show('Could not generate PDF: $e', title: 'Error', type: ToastType.error);
    }
  }

  Future<void> _sendEmail(BuildContext context, InvoiceModel inv) async {
    try {
      final client = HiveService.getClient(inv.clientId);
      final profile = HiveService.getProfile() ??
          UserProfileModel(businessName: 'My Business', email: '');
      if (client == null) return;
      final file = await PdfService.generateInvoicePdf(
        invoice: inv,
        client: client,
        business: profile,
      );
      await EmailService.sendInvoiceEmail(
        invoice: inv,
        client: client,
        business: profile,
        pdfFile: file,
      );
    } catch (e) {
      AppToast.show('Could not send email: $e', title: 'Error', type: ToastType.error);
    }
  }

  Future<void> _sharePdf(BuildContext context, InvoiceModel inv) async {
    try {
      final client = HiveService.getClient(inv.clientId);
      final profile = HiveService.getProfile() ??
          UserProfileModel(businessName: 'My Business', email: '');
      if (client == null) return;
      final file = await PdfService.generateInvoicePdf(
        invoice: inv,
        client: client,
        business: profile,
      );
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${inv.invoiceNumber} from ${profile.businessName}',
      );
    } catch (e) {
      AppToast.show('Could not share: $e', title: 'Error', type: ToastType.error);
    }
  }

  static const _headerStyle = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const _cellStyle = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 12,
    color: AppColors.textPrimary,
  );
}

class _MetaRow {
  final String label;
  final String value;
  const _MetaRow(this.label, this.value);
}

class _MetaSection extends StatelessWidget {
  final List<_MetaRow> rows;
  const _MetaSection({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${r.label}: ',
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: r.value,
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  const _TotalRow(this.label, this.value,
      {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: isBold ? 14 : 12,
                    fontWeight:
                        isBold ? FontWeight.w700 : FontWeight.w400,
                    color: color ?? AppColors.textSecondary)),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: isBold ? 14 : 12,
                    fontWeight:
                        isBold ? FontWeight.w700 : FontWeight.w500,
                    color: color ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 10,
                      color: c,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
