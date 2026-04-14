import 'package:hive/hive.dart';
import 'invoice_item_model.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 2)
class InvoiceModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String invoiceNumber;

  @HiveField(2)
  String clientId;

  @HiveField(3)
  DateTime invoiceDate;

  @HiveField(4)
  DateTime dueDate;

  @HiveField(5)
  List<InvoiceItemModel> items;

  @HiveField(6)
  bool applyGst;

  @HiveField(7)
  double gstPercent;

  @HiveField(8)
  String status; // 'draft' | 'sent' | 'paid' | 'overdue'

  @HiveField(9)
  String notes;

  @HiveField(10)
  double paymentMade;

  @HiveField(11)
  String terms;

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  bool isInterState;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.invoiceDate,
    required this.dueDate,
    required this.items,
    this.applyGst = false,
    this.gstPercent = 18.0,
    this.status = 'draft',
    this.notes = '',
    this.paymentMade = 0.0,
    this.terms = 'Due on Receipt',
    required this.createdAt,
    this.isInterState = false,
  });

  double get subTotal => items.fold(0, (sum, i) => sum + i.amount);
  double get gstAmount => applyGst ? subTotal * gstPercent / 100 : 0;
  double get cgstAmount => (!isInterState && applyGst) ? subTotal * gstPercent / 200 : 0;
  double get sgstAmount => (!isInterState && applyGst) ? subTotal * gstPercent / 200 : 0;
  double get igstAmount => (isInterState && applyGst) ? subTotal * gstPercent / 100 : 0;
  double get total => subTotal + gstAmount;
  double get balanceDue => total - paymentMade;

  bool get isOverdue =>
      status == 'sent' && dueDate.isBefore(DateTime.now());
}
