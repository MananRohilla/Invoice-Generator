import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/app_toast.dart';
import '../../data/models/client_model.dart';
import '../../data/models/invoice_item_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/pdf_service.dart';
import '../../routes/app_routes.dart';

class InvoiceListController extends GetxController {
  final invoices = <InvoiceModel>[].obs;
  final filteredInvoices = <InvoiceModel>[].obs;
  final selectedStatus = 'all'.obs;
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final searchController = TextEditingController();

  static const statuses = ['all', 'draft', 'sent', 'paid', 'overdue'];

  @override
  void onInit() {
    super.onInit();
    loadInvoices();
    ever(selectedStatus, (_) => _filter());
    debounce(searchQuery, (_) => _filter(),
        time: const Duration(milliseconds: 300));
  }

  void loadInvoices() {
    invoices.assignAll(HiveService.getAllInvoices());
    _filter();
  }

  void _filter() {
    var list = invoices.toList();
    if (selectedStatus.value != 'all') {
      list = list.where((i) => i.status == selectedStatus.value).toList();
    }
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      final clients = {for (var c in HiveService.getAllClients()) c.id: c};
      list = list.where((i) {
        final clientName = clients[i.clientId]?.name.toLowerCase() ?? '';
        return i.invoiceNumber.toLowerCase().contains(q) ||
            clientName.contains(q);
      }).toList();
    }
    filteredInvoices.assignAll(list);
  }

  void setStatus(String status) => selectedStatus.value = status;
  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchController.clear();
      searchQuery.value = '';
    }
  }

  String clientName(String clientId) =>
      HiveService.getClient(clientId)?.name ?? 'Unknown';

  void goToCreate() => Get.toNamed(AppRoutes.createInvoice);
  void goToPreview(InvoiceModel inv) =>
      Get.toNamed(AppRoutes.invoicePreview, arguments: inv);

  Future<void> deleteInvoice(String id) async {
    await HiveService.deleteInvoice(id);
    loadInvoices();
    AppToast.show('Invoice deleted', title: 'Deleted', type: ToastType.info);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class CreateInvoiceController extends GetxController {
  // Header fields
  final invoiceNumberController = TextEditingController();
  final invoiceDateController = TextEditingController();
  final dueDateController = TextEditingController();
  final selectedTerms = 'Due on Receipt'.obs;

  // Client
  final selectedClient = Rxn<ClientModel>();
  final clients = <ClientModel>[].obs;

  // Line items
  final items = <InvoiceItemModel>[].obs;

  // GST
  final applyGst = false.obs;
  final gstPercent = 18.0.obs;
  final isInterState = false.obs;

  // Totals
  final subTotal = 0.0.obs;
  final gstAmount = 0.0.obs;
  final cgstAmount = 0.0.obs;
  final sgstAmount = 0.0.obs;
  final igstAmount = 0.0.obs;
  final total = 0.0.obs;
  final paymentMadeController = TextEditingController();
  final balanceDue = 0.0.obs;

  // Notes
  final notesController = TextEditingController();
  final termsController = TextEditingController();

  static const termOptions = [
    'Due on Receipt',
    'Net 15',
    'Net 30',
    'Net 45',
  ];

  static const gstOptions = [0.0, 5.0, 12.0, 18.0, 28.0];

  final formKey = GlobalKey<FormState>();
  final isEditing = false.obs;
  InvoiceModel? editingInvoice;

  // Item text controllers (parallel to items list)
  final itemDescControllers = <TextEditingController>[].obs;
  final itemQtyControllers = <TextEditingController>[].obs;
  final itemRateControllers = <TextEditingController>[].obs;

  @override
  void onInit() {
    super.onInit();
    clients.assignAll(HiveService.getAllClients());
    final now = DateTime.now();
    invoiceNumberController.text = HiveService.generateInvoiceNumber();
    invoiceDateController.text = _fmt(now);
    dueDateController.text = _fmt(now);

    final args = Get.arguments;
    if (args is InvoiceModel) {
      isEditing.value = true;
      editingInvoice = args;
      _populateFromInvoice(args);
    } else {
      addItem();
    }

    ever(applyGst, (_) => recalculate());
    ever(gstPercent, (_) => recalculate());
    ever(isInterState, (_) => recalculate());
    ever(items, (_) => recalculate());
  }

  void _populateFromInvoice(InvoiceModel inv) {
    invoiceNumberController.text = inv.invoiceNumber;
    invoiceDateController.text = _fmt(inv.invoiceDate);
    dueDateController.text = _fmt(inv.dueDate);
    selectedTerms.value = inv.terms;
    selectedClient.value = HiveService.getClient(inv.clientId);
    applyGst.value = inv.applyGst;
    gstPercent.value = inv.gstPercent;
    isInterState.value = inv.isInterState;
    notesController.text = inv.notes;
    termsController.text = inv.terms;
    paymentMadeController.text =
        inv.paymentMade > 0 ? inv.paymentMade.toString() : '';

    for (final item in inv.items) {
      _addItemRow(item.description, item.quantity, item.rate);
    }
    recalculate();
  }

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  DateTime _parse(String s) {
    try {
      return DateFormat('dd/MM/yyyy').parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  void addItem() => _addItemRow('', 1, 0);

  void _addItemRow(String desc, double qty, double rate) {
    final d = TextEditingController(text: desc);
    final q = TextEditingController(text: qty == 0 ? '' : qty.toString());
    final r = TextEditingController(text: rate == 0 ? '' : rate.toString());

    void onChange() {
      final idx = itemDescControllers.indexOf(d);
      if (idx >= 0 && idx < items.length) {
        items[idx] = InvoiceItemModel(
          description: d.text,
          quantity: double.tryParse(q.text) ?? 0,
          rate: double.tryParse(r.text) ?? 0,
        );
        items.refresh();
        recalculate();
      }
    }

    d.addListener(onChange);
    q.addListener(onChange);
    r.addListener(onChange);

    itemDescControllers.add(d);
    itemQtyControllers.add(q);
    itemRateControllers.add(r);

    items.add(InvoiceItemModel(
      description: desc,
      quantity: qty,
      rate: rate,
    ));
    recalculate();
  }

  void removeItem(int index) {
    if (items.length <= 1) return;
    itemDescControllers[index].dispose();
    itemQtyControllers[index].dispose();
    itemRateControllers[index].dispose();
    itemDescControllers.removeAt(index);
    itemQtyControllers.removeAt(index);
    itemRateControllers.removeAt(index);
    items.removeAt(index);
    recalculate();
  }

  void recalculate() {
    final st = items.fold(0.0, (sum, i) => sum + i.amount);
    subTotal.value = st;

    if (applyGst.value) {
      final gst = st * gstPercent.value / 100;
      gstAmount.value = gst;
      if (isInterState.value) {
        igstAmount.value = gst;
        cgstAmount.value = 0;
        sgstAmount.value = 0;
      } else {
        cgstAmount.value = gst / 2;
        sgstAmount.value = gst / 2;
        igstAmount.value = 0;
      }
    } else {
      gstAmount.value = 0;
      cgstAmount.value = 0;
      sgstAmount.value = 0;
      igstAmount.value = 0;
    }

    total.value = st + gstAmount.value;
    final paid = double.tryParse(paymentMadeController.text) ?? 0;
    balanceDue.value = total.value - paid;
  }

  void devAutofill() {
    if (clients.isNotEmpty) selectedClient.value = clients.first;
    invoiceDateController.text = _fmt(DateTime.now());
    dueDateController.text = _fmt(DateTime.now());
    selectedTerms.value = 'Due on Receipt';
    notesController.text = 'Thanks for your business.';

    if (items.isNotEmpty) {
      itemDescControllers[0].text = 'Printer';
      itemQtyControllers[0].text = '1';
      itemRateControllers[0].text = '4000';
    }
    applyGst.value = false;
    recalculate();
  }

  Future<void> saveAsDraft() => _save('draft');
  Future<void> sendInvoice() => _save('sent');

  Future<void> generateInvoice() async {
    if (selectedClient.value == null) {
      AppToast.show('Please select a client', title: 'Error', type: ToastType.error);
      return;
    }
    if (items.every((i) => i.description.trim().isEmpty)) {
      AppToast.show('Add at least one line item', title: 'Error', type: ToastType.error);
      return;
    }

    final paid = double.tryParse(paymentMadeController.text) ?? 0;
    InvoiceModel invoice;

    if (isEditing.value && editingInvoice != null) {
      editingInvoice!
        ..clientId = selectedClient.value!.id
        ..invoiceDate = _parse(invoiceDateController.text)
        ..dueDate = _parse(dueDateController.text)
        ..items = items.toList()
        ..applyGst = applyGst.value
        ..gstPercent = gstPercent.value
        ..isInterState = isInterState.value
        ..status = 'paid'
        ..notes = notesController.text.trim()
        ..terms = selectedTerms.value
        ..paymentMade = paid;
      await HiveService.updateInvoice(editingInvoice!);
      invoice = editingInvoice!;
    } else {
      invoice = InvoiceModel(
        id: const Uuid().v4(),
        invoiceNumber: invoiceNumberController.text,
        clientId: selectedClient.value!.id,
        invoiceDate: _parse(invoiceDateController.text),
        dueDate: _parse(dueDateController.text),
        items: items.toList(),
        applyGst: applyGst.value,
        gstPercent: gstPercent.value,
        isInterState: isInterState.value,
        status: 'paid',
        notes: notesController.text.trim(),
        terms: selectedTerms.value,
        paymentMade: paid,
        createdAt: DateTime.now(),
      );
      await HiveService.addInvoice(invoice);
    }

    Get.offNamed(AppRoutes.invoiceDetails, arguments: invoice);
  }

  Future<void> _save(String status) async {
    if (selectedClient.value == null) {
      AppToast.show('Please select a client', title: 'Error', type: ToastType.error);
      return;
    }
    if (items.every((i) => i.description.trim().isEmpty)) {
      AppToast.show('Add at least one line item', title: 'Error', type: ToastType.error);
      return;
    }

    final paid = double.tryParse(paymentMadeController.text) ?? 0;

    if (isEditing.value && editingInvoice != null) {
      editingInvoice!
        ..clientId = selectedClient.value!.id
        ..invoiceDate = _parse(invoiceDateController.text)
        ..dueDate = _parse(dueDateController.text)
        ..items = items.toList()
        ..applyGst = applyGst.value
        ..gstPercent = gstPercent.value
        ..isInterState = isInterState.value
        ..status = status
        ..notes = notesController.text.trim()
        ..terms = selectedTerms.value
        ..paymentMade = paid;
      await HiveService.updateInvoice(editingInvoice!);
      Get.back(result: editingInvoice);
    } else {
      final invoice = InvoiceModel(
        id: const Uuid().v4(),
        invoiceNumber: invoiceNumberController.text,
        clientId: selectedClient.value!.id,
        invoiceDate: _parse(invoiceDateController.text),
        dueDate: _parse(dueDateController.text),
        items: items.toList(),
        applyGst: applyGst.value,
        gstPercent: gstPercent.value,
        isInterState: isInterState.value,
        status: status,
        notes: notesController.text.trim(),
        terms: selectedTerms.value,
        paymentMade: paid,
        createdAt: DateTime.now(),
      );
      await HiveService.addInvoice(invoice);
      Get.back(result: invoice);
    }
    AppToast.show(
      status == 'draft' ? 'Invoice saved as draft' : 'Invoice marked as sent',
      title: status == 'draft' ? 'Draft Saved' : 'Invoice Sent',
      type: ToastType.success,
    );
  }

  void goToPreview() {
    if (selectedClient.value == null) return;
    final paid = double.tryParse(paymentMadeController.text) ?? 0;
    final invoice = InvoiceModel(
      id: editingInvoice?.id ?? const Uuid().v4(),
      invoiceNumber: invoiceNumberController.text,
      clientId: selectedClient.value!.id,
      invoiceDate: _parse(invoiceDateController.text),
      dueDate: _parse(dueDateController.text),
      items: items.toList(),
      applyGst: applyGst.value,
      gstPercent: gstPercent.value,
      isInterState: isInterState.value,
      status: 'draft',
      notes: notesController.text.trim(),
      terms: selectedTerms.value,
      paymentMade: paid,
      createdAt: DateTime.now(),
    );
    Get.toNamed(AppRoutes.invoicePreview, arguments: invoice);
  }

  @override
  void onClose() {
    invoiceNumberController.dispose();
    invoiceDateController.dispose();
    dueDateController.dispose();
    notesController.dispose();
    termsController.dispose();
    paymentMadeController.dispose();
    for (final c in itemDescControllers) {
      c.dispose();
    }
    for (final c in itemQtyControllers) {
      c.dispose();
    }
    for (final c in itemRateControllers) {
      c.dispose();
    }
    super.onClose();
  }
}

class InvoicePreviewController extends GetxController {
  final invoice = Rxn<InvoiceModel>();
  final client = Rxn<ClientModel>();
  final isGeneratingPdf = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is InvoiceModel) {
      invoice.value = args;
      client.value = HiveService.getClient(args.clientId);
    }
  }

  Future<void> markAsPaid() async {
    final inv = invoice.value;
    if (inv == null) return;
    inv.status = 'paid';
    inv.paymentMade = inv.total;
    await HiveService.updateInvoice(inv);
    invoice.refresh();
    AppToast.show('Invoice marked as paid!', title: 'Paid', type: ToastType.success);
  }
}

class InvoiceDetailsController extends GetxController {
  final invoice = Rxn<InvoiceModel>();
  final client = Rxn<ClientModel>();
  final isGeneratingPdf = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is InvoiceModel) {
      invoice.value = args;
      client.value = HiveService.getClient(args.clientId);
    }
  }

  void refreshInvoice() {
    final inv = invoice.value;
    if (inv == null) return;
    invoice.value = HiveService.getInvoice(inv.id) ?? inv;
    client.value = HiveService.getClient(invoice.value!.clientId);
  }

  Future<void> markAsPaid() async {
    final inv = invoice.value;
    if (inv == null) return;
    inv.status = 'paid';
    inv.paymentMade = inv.total;
    await HiveService.updateInvoice(inv);
    invoice.refresh();
    AppToast.show('Invoice marked as paid!', title: 'Paid', type: ToastType.success);
  }

  Future<void> markAsSent() async {
    final inv = invoice.value;
    if (inv == null) return;
    inv.status = 'sent';
    inv.paymentMade = 0;
    await HiveService.updateInvoice(inv);
    invoice.refresh();
    AppToast.show('Invoice marked as sent.', title: 'Status Updated', type: ToastType.success);
  }

  Future<void> viewPdf() async {
    await _withPdfBytes((bytes) async {
      await Get.toNamed(
        AppRoutes.pdfViewer,
        arguments: {
          'bytes': bytes,
          'title': invoice.value?.invoiceNumber ?? 'Invoice PDF',
        },
      );
    });
  }

  Future<void> downloadPdf() async {
    await _withPdf((file) async {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${invoice.value?.invoiceNumber}.pdf',
      );
    });
  }

  Future<void> shareWhatsApp() async {
    await _withPdf((file) async {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: invoice.value?.invoiceNumber,
      );
    });
  }

  Future<void> shareInvoiceLink() async {
    final inv = invoice.value;
    final c = client.value;
    if (inv == null || c == null) return;
    final profile = HiveService.getProfile() ??
        UserProfileModel(businessName: 'My Business', email: '');
    final text = '''Invoice ${inv.invoiceNumber}
From: ${profile.businessName}
To: ${c.name}
Amount: ₹${inv.total.toStringAsFixed(2)}
Due: ${inv.dueDate.day}/${inv.dueDate.month}/${inv.dueDate.year}
Status: ${inv.status.toUpperCase()}''';
    await Share.share(text, subject: inv.invoiceNumber);
  }

  Future<void> _withPdf(Future<void> Function(dynamic file) action) async {
    final inv = invoice.value;
    final c = client.value;
    if (inv == null || c == null) return;
    isGeneratingPdf.value = true;
    try {
      final profile = HiveService.getProfile() ??
          UserProfileModel(businessName: 'My Business', email: '');
      final file = await PdfService.generateInvoicePdf(
        invoice: inv,
        client: c,
        business: profile,
      );
      await action(file);
    } catch (e) {
      AppToast.show('Could not generate PDF: $e', title: 'Error', type: ToastType.error);
    } finally {
      isGeneratingPdf.value = false;
    }
  }

  Future<void> _withPdfBytes(Future<void> Function(Uint8List bytes) action) async {
    final inv = invoice.value;
    final c = client.value;
    if (inv == null || c == null) return;
    isGeneratingPdf.value = true;
    try {
      final profile = HiveService.getProfile() ??
          UserProfileModel(businessName: 'My Business', email: '');
      final file = await PdfService.generateInvoicePdf(
        invoice: inv,
        client: c,
        business: profile,
      );
      final bytes = await file.readAsBytes();
      await action(bytes);
    } catch (e) {
      AppToast.show('Could not generate PDF: $e', title: 'Error', type: ToastType.error);
    } finally {
      isGeneratingPdf.value = false;
    }
  }
}
