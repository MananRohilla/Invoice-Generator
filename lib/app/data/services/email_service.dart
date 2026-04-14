import 'dart:io';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';
import '../models/client_model.dart';
import '../models/invoice_model.dart';
import '../models/user_profile_model.dart';

class EmailService {
  static Future<void> sendInvoiceEmail({
    required InvoiceModel invoice,
    required ClientModel client,
    required UserProfileModel business,
    required File pdfFile,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy');

    final body = '''Dear ${client.name},

Please find attached your invoice ${invoice.invoiceNumber} for ₹${invoice.total.toStringAsFixed(2)}.

Invoice Details:
  Invoice Number : ${invoice.invoiceNumber}
  Invoice Date   : ${dateFormat.format(invoice.invoiceDate)}
  Due Date       : ${dateFormat.format(invoice.dueDate)}
  Amount Due     : ₹${invoice.balanceDue.toStringAsFixed(2)}

${invoice.notes.isNotEmpty ? '${invoice.notes}\n' : ''}
Thank you for your business!

Regards,
${business.businessName}
${business.email}
${business.phone}''';

    final email = Email(
      body: body,
      subject: 'Invoice ${invoice.invoiceNumber} from ${business.businessName}',
      recipients: [client.email],
      attachmentPaths: [pdfFile.path],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }
}
