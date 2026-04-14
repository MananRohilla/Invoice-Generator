import 'package:hive/hive.dart';

part 'invoice_item_model.g.dart';

@HiveType(typeId: 1)
class InvoiceItemModel extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  double rate;

  InvoiceItemModel({
    required this.description,
    required this.quantity,
    required this.rate,
  });

  double get amount => quantity * rate;

  InvoiceItemModel copyWith({
    String? description,
    double? quantity,
    double? rate,
  }) {
    return InvoiceItemModel(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
    );
  }
}
