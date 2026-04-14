import 'package:get/get.dart';

import '../../data/models/invoice_model.dart';
import '../../data/services/hive_service.dart';

class ReportsController extends GetxController {
  final invoices = <InvoiceModel>[].obs;
  final monthlyRevenue = <String, double>{}.obs;
  final statusCounts = <String, int>{}.obs;
  final topClients = <_ClientStat>[].obs;
  final totalInvoiced = 0.0.obs;
  final totalCollected = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _calculate();
  }

  void _calculate() {
    final all = HiveService.getAllInvoices();
    invoices.assignAll(all);

    // Monthly revenue (last 6 months, paid invoices)
    final now = DateTime.now();
    final monthly = <String, double>{};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthly[key] = 0;
    }
    for (final inv in all) {
      if (inv.status == 'paid') {
        final key =
            '${inv.invoiceDate.year}-${inv.invoiceDate.month.toString().padLeft(2, '0')}';
        if (monthly.containsKey(key)) {
          monthly[key] = (monthly[key] ?? 0) + inv.total;
        }
      }
    }
    monthlyRevenue.assignAll(monthly);

    // Status counts
    statusCounts.assignAll({
      'paid': all.where((i) => i.status == 'paid').length,
      'sent': all.where((i) => i.status == 'sent').length,
      'draft': all.where((i) => i.status == 'draft').length,
      'overdue': all.where((i) => i.status == 'overdue').length,
    });

    // Top clients by revenue
    final clientRevenue = <String, double>{};
    for (final inv in all) {
      if (inv.status == 'paid') {
        clientRevenue[inv.clientId] =
            (clientRevenue[inv.clientId] ?? 0) + inv.total;
      }
    }
    final sorted = clientRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topClients.assignAll(sorted.take(5).map((e) {
      final name = HiveService.getClient(e.key)?.name ?? 'Unknown';
      return _ClientStat(name: name, revenue: e.value);
    }));

    totalInvoiced.value = all.fold(0, (sum, i) => sum + i.total);
    totalCollected.value = all
        .where((i) => i.status == 'paid')
        .fold(0, (sum, i) => sum + i.paymentMade);
  }
}

class _ClientStat {
  final String name;
  final double revenue;
  const _ClientStat({required this.name, required this.revenue});
}
