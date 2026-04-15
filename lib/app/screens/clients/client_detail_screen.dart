import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/client_model.dart';
import '../../data/services/hive_service.dart';
import '../../routes/app_routes.dart';
import '../invoices/widgets/status_chip.dart';

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Get.arguments as ClientModel;
    final invoices = HiveService.getInvoicesByClient(client.id);

    final totalBilled = invoices.fold(0.0, (sum, i) => sum + i.total);
    final totalPaid = invoices
        .where((i) => i.status == 'paid')
        .fold(0.0, (sum, i) => sum + i.paymentMade);
    final outstanding = invoices
        .where((i) => i.status != 'paid')
        .fold(0.0, (sum, i) => sum + i.balanceDue);

    final colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF34A853),
      const Color(0xFFF9AB00),
      AppColors.danger,
    ];
    final avatarColor = colors[client.name.codeUnits.isNotEmpty
        ? client.name.codeUnits.first % colors.length
        : 0];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          client.name,
          style: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () async {
              await Get.toNamed(AppRoutes.editClient, arguments: client);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Delete Client',
                      style: TextStyle(fontFamily: 'NotoSans')),
                  content: Text(
                      'Delete ${client.name}? All invoices for this client will remain.',
                      style: const TextStyle(fontFamily: 'NotoSans')),
                  actions: [
                    TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text('Delete',
                            style: TextStyle(color: AppColors.danger))),
                  ],
                ),
              );
              if (confirm == true) {
                await HiveService.deleteClient(client.id);
                Get.back();
                AppToast.show('${client.name} removed',
                    title: 'Deleted', type: ToastType.info);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Hero Card ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 64px avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: avatarColor,
                    child: Text(
                      client.initials,
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    client.name,
                    style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  if (client.gstin != null && client.gstin!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'GSTIN: ${client.gstin}',
                        style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _ContactRow(
                      icon: Icons.email_outlined, text: client.email),
                  if (client.phone.isNotEmpty)
                    _ContactRow(
                        icon: Icons.phone_outlined, text: client.phone),
                  if (client.address.isNotEmpty)
                    _ContactRow(
                        icon: Icons.location_on_outlined,
                        text: client.address),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Stats Row ─────────────────────────────────────────────────
            Row(
              children: [
                _StatBox(
                    label: 'Total Billed',
                    value: CurrencyFormatter.compact(totalBilled),
                    color: AppColors.primary),
                const SizedBox(width: 8),
                _StatBox(
                    label: 'Collected',
                    value: CurrencyFormatter.compact(totalPaid),
                    color: AppColors.success),
                const SizedBox(width: 8),
                _StatBox(
                    label: 'Outstanding',
                    value: CurrencyFormatter.compact(outstanding),
                    color: outstanding > 0
                        ? AppColors.warning
                        : AppColors.textHint),
              ],
            ),

            const SizedBox(height: 16),

            // ── Create Invoice button ─────────────────────────────────────
            GestureDetector(
              onTap: () async {
                await Get.toNamed(AppRoutes.createInvoice);
              },
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
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Create Invoice',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Invoice History ───────────────────────────────────────────
            if (invoices.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Invoice History',
                      style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(
                    'See All',
                    style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 13,
                        color: AppColors.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...invoices.map((inv) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
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
                              Text(inv.invoiceNumber,
                                  style: const TextStyle(
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary)),
                              Text(
                                DateFormatter.formatLong(inv.invoiceDate),
                                style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
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
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            StatusChip(status: inv.status),
                          ],
                        ),
                      ],
                    ),
                  )),
            ] else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Center(
                  child: Text('No invoices for this client yet',
                      style: TextStyle(
                          fontFamily: 'NotoSans',
                          color: AppColors.textHint,
                          fontSize: 13)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 10,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
