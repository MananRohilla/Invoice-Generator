import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/client_model.dart';
import '../../data/models/invoice_item_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/hive_service.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final _box = GetStorage();

  final isLoading = false.obs;

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await HiveService.saveUserFromGoogle(
          account.displayName,
          account.email,
          account.photoUrl,
        );
        final isNew = _box.read('dataSeedDone') != true;
        if (isNew) {
          await _seedMockData(account.displayName ?? 'User');
          _box.write('dataSeedDone', true);
        }
        _box.write('isLoggedIn', true);
        Get.offAllNamed(AppRoutes.shell);
      }
    } catch (e) {
      Get.snackbar('Sign-in Error', 'Could not sign in. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
      debugPrint('Google Sign-In error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Dev bypass — skips Google Sign-In in debug mode
  Future<void> devSignIn() async {
    await HiveService.saveUserFromGoogle(
      'Manan Rohilla',
      'mananr0135@gmail.com',
      null,
    );
    final isNew = _box.read('dataSeedDone') != true;
    if (isNew) {
      await _seedMockData('Manan');
      _box.write('dataSeedDone', true);
    }
    _box.write('isLoggedIn', true);
    Get.offAllNamed(AppRoutes.shell);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _box.write('isLoggedIn', false);
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _seedMockData(String userName) async {
    final uuid = const Uuid();
    final now = DateTime.now();

    // Seed 2 clients
    final client1 = ClientModel(
      id: uuid.v4(),
      name: 'Sanjay Hooda',
      email: 'sanjay.hooda@example.com',
      phone: '+91 98765 43210',
      address: 'B-42, Sector 18, Gurugram, Haryana 122001',
      gstin: '06AABCU9603R1ZX',
      createdAt: now.subtract(const Duration(days: 30)),
    );

    final client2 = ClientModel(
      id: uuid.v4(),
      name: 'Priya Sharma',
      email: 'priya.sharma@techcorp.in',
      phone: '+91 91234 56789',
      address: '14, Connaught Place, New Delhi 110001',
      createdAt: now.subtract(const Duration(days: 15)),
    );

    await HiveService.addClient(client1);
    await HiveService.addClient(client2);

    // Seed 3 invoices
    final inv1 = InvoiceModel(
      id: uuid.v4(),
      invoiceNumber: HiveService.generateInvoiceNumber(),
      clientId: client1.id,
      invoiceDate: now.subtract(const Duration(days: 20)),
      dueDate: now.subtract(const Duration(days: 10)),
      items: [
        InvoiceItemModel(description: 'Printer', quantity: 1, rate: 4000),
      ],
      applyGst: false,
      status: 'paid',
      paymentMade: 4000,
      notes: 'Thank you for your business!',
      terms: 'Due on Receipt',
      createdAt: now.subtract(const Duration(days: 20)),
    );

    final inv2 = InvoiceModel(
      id: uuid.v4(),
      invoiceNumber: HiveService.generateInvoiceNumber(),
      clientId: client2.id,
      invoiceDate: now.subtract(const Duration(days: 10)),
      dueDate: now.add(const Duration(days: 20)),
      items: [
        InvoiceItemModel(description: 'Web Development Services', quantity: 1, rate: 12500),
      ],
      applyGst: true,
      gstPercent: 18,
      status: 'sent',
      paymentMade: 0,
      notes: 'Please pay within 30 days.',
      terms: 'Net 30',
      createdAt: now.subtract(const Duration(days: 10)),
    );

    final inv3 = InvoiceModel(
      id: uuid.v4(),
      invoiceNumber: HiveService.generateInvoiceNumber(),
      clientId: client1.id,
      invoiceDate: now,
      dueDate: now.add(const Duration(days: 15)),
      items: [
        InvoiceItemModel(description: 'Consulting Services', quantity: 8, rate: 1000),
      ],
      applyGst: false,
      status: 'draft',
      paymentMade: 0,
      notes: '',
      terms: 'Net 15',
      createdAt: now,
    );

    await HiveService.addInvoice(inv1);
    await HiveService.addInvoice(inv2);
    await HiveService.addInvoice(inv3);
  }
}
