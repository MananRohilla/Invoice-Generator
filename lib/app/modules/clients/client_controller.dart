import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/client_model.dart';
import '../../data/services/hive_service.dart';
import '../../routes/app_routes.dart';

class ClientController extends GetxController {
  final clients = <ClientModel>[].obs;
  final filteredClients = <ClientModel>[].obs;
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadClients();
    debounce(searchQuery, (_) => _filterClients(),
        time: const Duration(milliseconds: 300));
  }

  void loadClients() {
    clients.assignAll(HiveService.getAllClients());
    filteredClients.assignAll(clients);
  }

  void _filterClients() {
    if (searchQuery.value.isEmpty) {
      filteredClients.assignAll(clients);
    } else {
      final q = searchQuery.value.toLowerCase();
      filteredClients.assignAll(clients.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.phone.contains(q)));
    }
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchController.clear();
      searchQuery.value = '';
    }
  }

  void goToAdd() => Get.toNamed(AppRoutes.addClient);

  void goToEdit(ClientModel client) =>
      Get.toNamed(AppRoutes.editClient, arguments: client);

  void goToDetail(ClientModel client) =>
      Get.toNamed(AppRoutes.clientDetail, arguments: client);

  Future<void> deleteClient(String id) async {
    await HiveService.deleteClient(id);
    loadClients();
    Get.snackbar('Deleted', 'Client removed successfully',
        snackPosition: SnackPosition.BOTTOM);
  }

  int invoiceCountForClient(String clientId) =>
      HiveService.getInvoicesByClient(clientId).length;

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class AddClientController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final gstinController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final isEditing = false.obs;
  ClientModel? editingClient;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is ClientModel) {
      isEditing.value = true;
      editingClient = args;
      nameController.text = args.name;
      emailController.text = args.email;
      phoneController.text = args.phone;
      addressController.text = args.address;
      gstinController.text = args.gstin ?? '';
    }
  }

  void devAutofill() {
    nameController.text = 'Sanjay Hooda';
    emailController.text = 'sanjay.hooda@example.com';
    phoneController.text = '+91 98765 43210';
    addressController.text = 'B-42, Sector 18, Gurugram, Haryana 122001';
    gstinController.text = '06AABCU9603R1ZX';
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    if (isEditing.value && editingClient != null) {
      editingClient!.name = nameController.text.trim();
      editingClient!.email = emailController.text.trim();
      editingClient!.phone = phoneController.text.trim();
      editingClient!.address = addressController.text.trim();
      editingClient!.gstin = gstinController.text.trim().isEmpty
          ? null
          : gstinController.text.trim();
      await HiveService.updateClient(editingClient!);
      Get.back();
      Get.snackbar('Updated', 'Client updated successfully',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      final client = ClientModel(
        id: const Uuid().v4(),
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        gstin: gstinController.text.trim().isEmpty
            ? null
            : gstinController.text.trim(),
        createdAt: DateTime.now(),
      );
      await HiveService.addClient(client);
      Get.back(result: client);
      Get.snackbar('Added', 'Client added successfully',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    gstinController.dispose();
    super.onClose();
  }
}
