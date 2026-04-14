import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/number_to_words.dart';
import '../models/client_model.dart';
import '../models/invoice_model.dart';
import '../models/user_profile_model.dart';

class PdfService {
  static Future<File> generateInvoicePdf({
    required InvoiceModel invoice,
    required ClientModel client,
    required UserProfileModel business,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final regularFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final boldFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    final italicFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Italic.ttf'));

    final dateFormat = DateFormat('dd/MM/yyyy');
    final numFormat = NumberFormat('#,##,##0.00', 'en_IN');

    String fmt(double v) => numFormat.format(v);

    // Colors
    const headerBg = PdfColor.fromInt(0xFFE8F0FE);
    const primary = PdfColor.fromInt(0xFF1A73E8);
    const textPrimary = PdfColor.fromInt(0xFF202124);
    const textSecondary = PdfColor.fromInt(0xFF5F6368);
    const dividerColor = PdfColor.fromInt(0xFFE0E0E0);
    const successGreen = PdfColor.fromInt(0xFF34A853);

    pw.TextStyle regular(double size, {PdfColor? color}) => pw.TextStyle(
          font: regularFont,
          fontSize: size,
          color: color ?? textPrimary,
        );
    pw.TextStyle bold(double size, {PdfColor? color}) => pw.TextStyle(
          font: boldFont,
          fontSize: size,
          color: color ?? textPrimary,
        );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(business.businessName,
                        style: bold(20, color: primary)),
                    if (business.address.isNotEmpty)
                      pw.Text(business.address,
                          style: regular(9, color: textSecondary)),
                    if (business.email.isNotEmpty)
                      pw.Text(business.email,
                          style: regular(9, color: textSecondary)),
                    if (business.phone.isNotEmpty)
                      pw.Text(business.phone,
                          style: regular(9, color: textSecondary)),
                    if (business.gstin != null)
                      pw.Text('GSTIN: ${business.gstin}',
                          style: regular(9, color: textSecondary)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE',
                        style: bold(18, color: primary)),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: invoice.status == 'paid'
                            ? successGreen
                            : invoice.status == 'sent'
                                ? primary
                                : PdfColors.grey400,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        invoice.status.toUpperCase(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Divider(color: dividerColor, thickness: 0.5),
            pw.SizedBox(height: 12),

            // ── Invoice Meta ────────────────────────────────────────────────
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _metaRow('Invoice #', invoice.invoiceNumber, regular, bold),
                      pw.SizedBox(height: 4),
                      _metaRow('Invoice Date',
                          dateFormat.format(invoice.invoiceDate), regular, bold),
                      pw.SizedBox(height: 4),
                      _metaRow('Terms', invoice.terms, regular, bold),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _metaRow('Due Date',
                          dateFormat.format(invoice.dueDate), regular, bold),
                      if (invoice.balanceDue <= 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('PAID IN FULL',
                            style: bold(10, color: successGreen)),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Divider(color: dividerColor, thickness: 0.5),
            pw.SizedBox(height: 12),

            // ── Bill To ─────────────────────────────────────────────────────
            pw.Text('Bill To', style: regular(10, color: textSecondary)),
            pw.SizedBox(height: 4),
            pw.Text(client.name, style: bold(12)),
            if (client.address.isNotEmpty)
              pw.Text(client.address,
                  style: regular(9, color: textSecondary)),
            if (client.email.isNotEmpty)
              pw.Text(client.email,
                  style: regular(9, color: textSecondary)),
            if (client.phone.isNotEmpty)
              pw.Text(client.phone,
                  style: regular(9, color: textSecondary)),
            if (client.gstin != null)
              pw.Text('GSTIN: ${client.gstin}',
                  style: regular(9, color: textSecondary)),

            pw.SizedBox(height: 14),

            // ── Items Table ─────────────────────────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(
                color: dividerColor,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FixedColumnWidth(50),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FixedColumnWidth(70),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: headerBg),
                  children: [
                    _tableHeader('#', boldFont),
                    _tableHeader('Item & Description', boldFont),
                    _tableHeader('Qty', boldFont),
                    _tableHeader('Rate', boldFont),
                    _tableHeader('Amount', boldFont),
                  ],
                ),
                // Item rows
                ...invoice.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _tableCell('${i + 1}', regularFont),
                      _tableCell(item.description, regularFont),
                      _tableCell(fmt(item.quantity), regularFont,
                          align: pw.TextAlign.center),
                      _tableCell(fmt(item.rate), regularFont,
                          align: pw.TextAlign.right),
                      _tableCell(fmt(item.amount), regularFont,
                          align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 12),

            // ── Total In Words ───────────────────────────────────────────────
            pw.Text(
              NumberToWords.toWords(invoice.total),
              style: pw.TextStyle(
                font: italicFont,
                fontSize: 9,
                color: textSecondary,
              ),
            ),

            if (invoice.notes.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text('Notes: ${invoice.notes}',
                  style: regular(9, color: textSecondary)),
            ],

            pw.SizedBox(height: 12),

            // ── Totals ───────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _totalRow('Sub Total', fmt(invoice.subTotal), regular, bold,
                        isHeader: false),
                    if (invoice.applyGst) ...[
                      if (!invoice.isInterState) ...[
                        _totalRow(
                            'CGST (${invoice.gstPercent / 2}%)',
                            fmt(invoice.cgstAmount),
                            regular,
                            bold),
                        _totalRow(
                            'SGST (${invoice.gstPercent / 2}%)',
                            fmt(invoice.sgstAmount),
                            regular,
                            bold),
                      ] else
                        _totalRow(
                            'IGST (${invoice.gstPercent}%)',
                            fmt(invoice.igstAmount),
                            regular,
                            bold),
                    ],
                    pw.Divider(color: dividerColor, thickness: 0.5),
                    _totalRow(
                        'Total', '₹${fmt(invoice.total)}', regular, bold,
                        isHeader: true),
                    if (invoice.paymentMade > 0)
                      _totalRow(
                          'Payment Made',
                          '(-) ₹${fmt(invoice.paymentMade)}',
                          regular,
                          bold),
                    _totalRow(
                        'Balance Due', '₹${fmt(invoice.balanceDue)}', regular,
                        bold,
                        isHeader: true,
                        color: invoice.balanceDue <= 0
                            ? successGreen
                            : primary),
                  ],
                ),
              ],
            ),

            pw.Spacer(),

            // ── Signature ────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 120,
                      height: 0.5,
                      color: textPrimary,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signature',
                        style: regular(9, color: textSecondary)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Divider(color: dividerColor, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Generated by InvoGen — Professional Invoice Generator',
                style: regular(8, color: PdfColors.grey500),
              ),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _metaRow(
    String label,
    String value,
    pw.TextStyle Function(double, {PdfColor? color}) regular,
    pw.TextStyle Function(double, {PdfColor? color}) bold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text('$label :', style: regular(9)),
        ),
        pw.Text(value, style: bold(9)),
      ],
    );
  }

  static pw.Widget _tableHeader(String text, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: boldFont, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value,
    pw.TextStyle Function(double, {PdfColor? color}) regular,
    pw.TextStyle Function(double, {PdfColor? color}) bold, {
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label,
                style: isHeader ? bold(10) : regular(9),
                textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 16),
          pw.SizedBox(
            width: 90,
            child: pw.Text(value,
                style: isHeader
                    ? bold(10, color: color)
                    : regular(9, color: color),
                textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }
}
