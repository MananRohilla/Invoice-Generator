import 'package:hive_flutter/hive_flutter.dart';
import '../models/client_model.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';
import '../models/user_profile_model.dart';

class HiveService {
  HiveService._();

  static late Box<ClientModel> _clientBox;
  static late Box<InvoiceModel> _invoiceBox;
  static late Box<UserProfileModel> _profileBox;
  static late Box _settingsBox;

  static Future<void> init() async {
    _clientBox = await Hive.openBox<ClientModel>('clients');
    _invoiceBox = await Hive.openBox<InvoiceModel>('invoices');
    _profileBox = await Hive.openBox<UserProfileModel>('userProfile');
    _settingsBox = await Hive.openBox('appSettings');
  }

  // ─── Invoice Number ───────────────────────────────────────────────────────
  static String generateInvoiceNumber() {
    int counter = (_settingsBox.get('invoiceCounter', defaultValue: 0) as int) + 1;
    _settingsBox.put('invoiceCounter', counter);
    return 'INV-${counter.toString().padLeft(6, '0')}';
  }

  // ─── Clients ─────────────────────────────────────────────────────────────
  static List<ClientModel> getAllClients() {
    return _clientBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static ClientModel? getClient(String id) {
    return _clientBox.values.firstWhere(
      (c) => c.id == id,
      orElse: () => ClientModel(
        id: '', name: '', email: '', phone: '', address: '',
        createdAt: DateTime.now(),
      ),
    );
  }

  static Future<void> addClient(ClientModel client) async {
    await _clientBox.put(client.id, client);
  }

  static Future<void> updateClient(ClientModel client) async {
    await _clientBox.put(client.id, client);
  }

  static Future<void> deleteClient(String id) async {
    await _clientBox.delete(id);
  }

  // ─── Invoices ─────────────────────────────────────────────────────────────
  static List<InvoiceModel> getAllInvoices() {
    final invoices = _invoiceBox.values.toList();
    // Update overdue status
    for (final inv in invoices) {
      if (inv.status == 'sent' && inv.dueDate.isBefore(DateTime.now())) {
        inv.status = 'overdue';
        inv.save();
      }
    }
    return invoices..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<InvoiceModel> getInvoicesByClient(String clientId) {
    return getAllInvoices().where((i) => i.clientId == clientId).toList();
  }

  static InvoiceModel? getInvoice(String id) {
    return _invoiceBox.get(id);
  }

  static Future<void> addInvoice(InvoiceModel invoice) async {
    await _invoiceBox.put(invoice.id, invoice);
  }

  static Future<void> updateInvoice(InvoiceModel invoice) async {
    await _invoiceBox.put(invoice.id, invoice);
  }

  static Future<void> deleteInvoice(String id) async {
    await _invoiceBox.delete(id);
  }

  // ─── User Profile ─────────────────────────────────────────────────────────
  static UserProfileModel? getProfile() {
    return _profileBox.get('profile');
  }

  static Future<void> saveProfile(UserProfileModel profile) async {
    await _profileBox.put('profile', profile);
  }

  static Future<void> saveUserFromGoogle(
    String? displayName,
    String? email,
    String? photoUrl,
  ) async {
    final existing = _profileBox.get('profile');
    if (existing != null) {
      existing.googleDisplayName = displayName;
      existing.googlePhotoUrl = photoUrl;
      if (email != null) existing.email = email;
      await existing.save();
    } else {
      await _profileBox.put(
        'profile',
        UserProfileModel(
          businessName: displayName ?? 'My Business',
          email: email ?? '',
          googleDisplayName: displayName,
          googlePhotoUrl: photoUrl,
        ),
      );
    }
  }

  // ─── Stats ────────────────────────────────────────────────────────────────
  static double getTotalRevenue() {
    return getAllInvoices()
        .where((i) => i.status == 'paid')
        .fold(0.0, (sum, i) => sum + i.total);
  }

  static double getTotalPending() {
    return getAllInvoices()
        .where((i) => i.status == 'sent')
        .fold(0.0, (sum, i) => sum + i.balanceDue);
  }

  static int getOverdueCount() {
    return getAllInvoices().where((i) => i.status == 'overdue').length;
  }
}
