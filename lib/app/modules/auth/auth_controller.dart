import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/client_model.dart';
import '../../data/models/invoice_item_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/hive_service.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final _box = GetStorage();

  final isLoading = false.obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> _completeSignIn(String name, String email) async {
    await HiveService.saveUserFromGoogle(name, email, null);
    if (_box.read('dataSeedDone') != true) {
      await _seedMockData(name);
      _box.write('dataSeedDone', true);
    }
    _box.write('isLoggedIn', true);
    Get.offAllNamed(AppRoutes.shell);
  }

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    // Simulated Google sign-in delay for visual effect
    await Future.delayed(const Duration(milliseconds: 1500));
    await _completeSignIn('Google User', 'user@gmail.com');
  }

  Future<void> signInWithEmail() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    final email = emailController.text.trim().isEmpty
        ? 'user@example.com'
        : emailController.text.trim();
    await _completeSignIn('Email User', email);
  }

  Future<void> signInWithPhone() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    final phone = phoneController.text.trim().isEmpty
        ? '9999999999'
        : phoneController.text.trim();
    await _completeSignIn('Phone User', '$phone@phone.local');
  }

  // Quick bypass — always visible
  Future<void> devSignIn() async {
    await _completeSignIn('Manan Rohilla', 'mananr0135@gmail.com');
  }

  Future<void> signOut() async {
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
