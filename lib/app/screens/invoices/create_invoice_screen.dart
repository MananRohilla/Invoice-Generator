import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../modules/invoices/invoice_controller.dart';

class CreateInvoiceScreen extends GetView<CreateInvoiceController> {
  const CreateInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(
            controller.isEditing.value ? 'Edit Invoice' : 'New Invoice')),
        actions: [
          TextButton(
            onPressed: controller.saveAsDraft,
            child: const Text('SAVE DRAFT',
                style: TextStyle(
                    fontFamily: 'NotoSans',
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          children: [
            // Dev Autofill
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.developer_mode,
                        color: Colors.white, size: 18),
                    label: const Text('Dev Fill',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'NotoSans')),
                    onPressed: controller.devAutofill,
                  ),
                ),
              ),

            // ── Card 1: Invoice Header ─────────────────────────────────────
            _SectionCard(
              title: 'Invoice Details',
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.invoiceNumberController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number',
                      prefixIcon: Icon(Icons.tag, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Invoice Date',
                          controller: controller.invoiceDateController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'Due Date',
                          controller: controller.dueDateController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Obx(() => DropdownButtonFormField<String>(
                        key: ValueKey(controller.selectedTerms.value),
                        initialValue: controller.selectedTerms.value,
                        decoration: const InputDecoration(
                          labelText: 'Payment Terms',
                        ),
                        items: CreateInvoiceController.termOptions
                            .map((t) => DropdownMenuItem(
                                value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) =>
                            controller.selectedTerms.value = v!,
                        style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 14,
                            color: AppColors.textPrimary),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Card 2: Bill To ────────────────────────────────────────────
            _SectionCard(
              title: 'Bill To',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => DropdownButtonFormField(
                        value: controller.selectedClient.value,
                        decoration: const InputDecoration(
                          labelText: 'Select Client *',
                          prefixIcon:
                              Icon(Icons.people_outline_rounded, size: 18),
                        ),
                        hint: const Text('Choose a client',
                            style: TextStyle(
                                fontFamily: 'NotoSans',
                                color: AppColors.textHint)),
                        items: controller.clients
                            .map((cl) => DropdownMenuItem(
                                  value: cl,
                                  child: Text(cl.name,
                                      style: const TextStyle(
                                          fontFamily: 'NotoSans',
                                          fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            controller.selectedClient.value = v,
                        style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 14,
                            color: AppColors.textPrimary),
                      )),
                  Obx(() {
                    final cl = controller.selectedClient.value;
                    if (cl == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cl.name,
                              style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.primary)),
                          if (cl.email.isNotEmpty)
                            Text(cl.email,
                                style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          if (cl.address.isNotEmpty)
                            Text(cl.address,
                                style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Card 3: Line Items ─────────────────────────────────────────
            _SectionCard(
              title: 'Line Items',
              trailing: TextButton.icon(
                onPressed: controller.addItem,
                icon: const Icon(Icons.add_circle_outline,
                    size: 16, color: AppColors.primary),
                label: const Text('Add Item',
                    style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: AppColors.primary)),
              ),
              child: Column(
                children: [
                  // Table header
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 5,
                            child: Text('Description',
                                style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                        SizedBox(width: 6),
                        SizedBox(
                            width: 48,
                            child: Text('Qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                        SizedBox(width: 6),
                        SizedBox(
                            width: 60,
                            child: Text('Rate',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                        SizedBox(width: 6),
                        SizedBox(
                            width: 64,
                            child: Text('Amount',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600))),
                        SizedBox(width: 24),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Item rows
                  Obx(() => Column(
                        children: List.generate(
                            controller.itemDescControllers.length, (i) {
                          return _ItemRow(
                            index: i,
                            descController:
                                controller.itemDescControllers[i],
                            qtyController:
                                controller.itemQtyControllers[i],
                            rateController:
                                controller.itemRateControllers[i],
                            amount: controller.items.length > i
                                ? controller.items[i].amount
                                : 0,
                            onRemove: () => controller.removeItem(i),
                            canRemove:
                                controller.items.length > 1,
                          );
                        }),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Card 4: GST / Tax ──────────────────────────────────────────
            _SectionCard(
              title: 'Tax / GST',
              child: Column(
                children: [
                  Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Apply GST',
                            style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        value: controller.applyGst.value,
                        onChanged: (v) => controller.applyGst.value = v,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryLight,
                      )),
                  Obx(() {
                    if (!controller.applyGst.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<double>(
                                key: ValueKey(controller.gstPercent.value),
                                initialValue: controller.gstPercent.value,
                                decoration: const InputDecoration(
                                    labelText: 'GST Rate'),
                                items: CreateInvoiceController.gstOptions
                                    .map((g) => DropdownMenuItem(
                                        value: g,
                                        child: Text('$g%',
                                            style: const TextStyle(
                                                fontFamily: 'NotoSans',
                                                fontSize: 14))))
                                    .toList(),
                                onChanged: (v) =>
                                    controller.gstPercent.value = v!,
                                style: const TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 14,
                                    color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Type',
                                      style: TextStyle(
                                          fontFamily: 'NotoSans',
                                          fontSize: 13,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Obx(() => Row(
                                        children: [
                                          _GstTypeChip(
                                            label: 'Intra',
                                            selected: !controller
                                                .isInterState.value,
                                            onTap: () => controller
                                                .isInterState.value = false,
                                          ),
                                          const SizedBox(width: 8),
                                          _GstTypeChip(
                                            label: 'Inter',
                                            selected: controller
                                                .isInterState.value,
                                            onTap: () => controller
                                                .isInterState.value = true,
                                          ),
                                        ],
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Card 5: Summary ────────────────────────────────────────────
            _SectionCard(
              title: 'Summary',
              child: Obx(() => Column(
                    children: [
                      _SummaryRow(
                          label: 'Sub Total',
                          value: CurrencyFormatter.format(
                              controller.subTotal.value)),
                      if (controller.applyGst.value) ...[
                        if (!controller.isInterState.value) ...[
                          _SummaryRow(
                              label:
                                  'CGST (${controller.gstPercent.value / 2}%)',
                              value: CurrencyFormatter.format(
                                  controller.cgstAmount.value)),
                          _SummaryRow(
                              label:
                                  'SGST (${controller.gstPercent.value / 2}%)',
                              value: CurrencyFormatter.format(
                                  controller.sgstAmount.value)),
                        ] else
                          _SummaryRow(
                              label:
                                  'IGST (${controller.gstPercent.value}%)',
                              value: CurrencyFormatter.format(
                                  controller.igstAmount.value)),
                      ],
                      const Divider(height: 16),
                      _SummaryRow(
                          label: 'Total',
                          value: CurrencyFormatter.format(
                              controller.total.value),
                          isBold: true),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controller.paymentMadeController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'))
                        ],
                        onChanged: (_) => controller.recalculate(),
                        decoration: const InputDecoration(
                          labelText: 'Payment Received (₹)',
                          prefixText: '₹ ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.balanceDue.value <= 0
                              ? AppColors.successLight
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Balance Due',
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: controller.balanceDue.value <= 0
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                  controller.balanceDue.value),
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: controller.balanceDue.value <= 0
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            ),

            const SizedBox(height: 12),

            // ── Card 6: Notes & Terms ──────────────────────────────────────
            _SectionCard(
              title: 'Notes & Terms',
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Customer Notes',
                      hintText: 'Thanks for your business.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Authorized Signature',
                            style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 11,
                                color: AppColors.textHint)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Action Bar ──────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            // Save Draft — outlined
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: controller.saveAsDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SAVE DRAFT',
                      style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Mark as Sent — gradient filled
            Expanded(
              child: GestureDetector(
                onTap: controller.generateInvoice,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'MARK AS SENT',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item Row ──────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final int index;
  final TextEditingController descController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final double amount;
  final VoidCallback onRemove;
  final bool canRemove;

  const _ItemRow({
    required this.index,
    required this.descController,
    required this.qtyController,
    required this.rateController,
    required this.amount,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextField(
              controller: descController,
              decoration: InputDecoration(
                hintText: 'Item description',
                hintStyle:
                    const TextStyle(fontSize: 12, color: AppColors.textHint),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(
                  fontFamily: 'NotoSans', fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 48,
            child: TextField(
              controller: qtyController,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'))
              ],
              decoration: const InputDecoration(
                hintText: '1',
                hintStyle:
                    TextStyle(fontSize: 12, color: AppColors.textHint),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(
                  fontFamily: 'NotoSans', fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: TextField(
              controller: rateController,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'))
              ],
              decoration: const InputDecoration(
                hintText: '0.00',
                hintStyle:
                    TextStyle(fontSize: 12, color: AppColors.textHint),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(
                  fontFamily: 'NotoSans', fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                CurrencyFormatter.formatNoSymbol(amount),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: canRemove
                ? IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: AppColors.textHint),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              if (trailing != null) trailing!,
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  const _SummaryRow(
      {required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: isBold ? 14 : 13,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w400,
                  color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: isBold ? 14 : 13,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Date Field ────────────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _DateField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined,
            size: 16, color: AppColors.textHint),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _parse(controller.text),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => child!,
        );
        if (picked != null) {
          controller.text =
              DateFormat('dd/MM/yyyy').format(picked);
        }
      },
    );
  }

  DateTime _parse(String s) {
    try {
      return DateFormat('dd/MM/yyyy').parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }
}

// ── GST Type Chip ─────────────────────────────────────────────────────────────
class _GstTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GstTypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
