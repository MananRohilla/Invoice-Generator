import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/user_profile_model.dart';
import '../../data/services/hive_service.dart';
import '../../modules/auth/auth_controller.dart';

class ProfileController extends GetxController {
  final businessNameController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final gstinController = TextEditingController();
  final defaultNotesController = TextEditingController();

  final selectedDefaultGst = 18.0.obs;
  final selectedDefaultTerms = 'Due on Receipt'.obs;
  final logoPath = Rxn<String>();
  final userProfile = Rxn<UserProfileModel>();

  static const gstOptions = [0.0, 5.0, 12.0, 18.0, 28.0];
  static const termOptions = ['Due on Receipt', 'Net 15', 'Net 30', 'Net 45'];

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  void _loadProfile() {
    final p = HiveService.getProfile();
    userProfile.value = p;
    if (p != null) {
      businessNameController.text = p.businessName;
      addressController.text = p.address;
      emailController.text = p.email;
      phoneController.text = p.phone;
      gstinController.text = p.gstin ?? '';
      defaultNotesController.text = p.defaultNotes;
      selectedDefaultGst.value = p.defaultGstRate;
      selectedDefaultTerms.value = p.defaultTerms;
      logoPath.value = p.logoPath;
    }
  }

  void devAutofill() {
    businessNameController.text = 'Cabiverse';
    addressController.text = 'B-12, Sector 74, Noida, Uttar Pradesh 201301';
    emailController.text = 'info@cabiverse.com';
    phoneController.text = '+91 98109 87654';
    gstinController.text = '09AABCC1234D1ZX';
    defaultNotesController.text = 'Thank you for your business!';
    selectedDefaultGst.value = 18.0;
    selectedDefaultTerms.value = 'Due on Receipt';
  }

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) {
      logoPath.value = picked.path;
    }
  }

  Future<void> save() async {
    final existing = userProfile.value;
    if (existing != null) {
      existing
        ..businessName = businessNameController.text.trim()
        ..address = addressController.text.trim()
        ..email = emailController.text.trim()
        ..phone = phoneController.text.trim()
        ..gstin = gstinController.text.trim().isEmpty
            ? null
            : gstinController.text.trim()
        ..defaultNotes = defaultNotesController.text.trim()
        ..defaultGstRate = selectedDefaultGst.value
        ..defaultTerms = selectedDefaultTerms.value
        ..logoPath = logoPath.value;
      await HiveService.saveProfile(existing);
    } else {
      final p = UserProfileModel(
        businessName: businessNameController.text.trim(),
        address: addressController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        gstin: gstinController.text.trim().isEmpty
            ? null
            : gstinController.text.trim(),
        defaultNotes: defaultNotesController.text.trim(),
        defaultGstRate: selectedDefaultGst.value,
        defaultTerms: selectedDefaultTerms.value,
        logoPath: logoPath.value,
      );
      await HiveService.saveProfile(p);
    }
    Get.back();
    Get.snackbar('Saved', 'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM);
  }

  void signOut() {
    Get.find<AuthController>().signOut();
  }

  @override
  void onClose() {
    businessNameController.dispose();
    addressController.dispose();
    emailController.dispose();
    phoneController.dispose();
    gstinController.dispose();
    defaultNotesController.dispose();
    super.onClose();
  }
}
