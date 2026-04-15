import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../modules/clients/client_controller.dart';

class AddClientScreen extends GetView<AddClientController> {
  const AddClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(
            controller.isEditing.value ? 'Edit Client' : 'New Client')),
        actions: [
          TextButton(
            onPressed: controller.save,
            child: const Text(
              'SAVE',
              style: TextStyle(
                fontFamily: 'NotoSans',
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dev Autofill
              if (kDebugMode)
                SizedBox(
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
              if (kDebugMode) const SizedBox(height: 16),

              // Customer Information card
              _FormCard(
                title: 'Customer Information',
                children: [
                  _FormField(
                    label: 'Client Name',
                    controller: controller.nameController,
                    required: true,
                    hint: 'Full name or company name',
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 16),
                  _FormField(
                    label: 'Email Address',
                    controller: controller.emailController,
                    required: true,
                    hint: 'client@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!GetUtils.isEmail(v.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _FormField(
                    label: 'Phone Number',
                    controller: controller.phoneController,
                    required: true,
                    hint: '+91 98765 43210',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Billing Address card
              _FormCard(
                title: 'Billing Address',
                children: [
                  TextFormField(
                    controller: controller.addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Street, City, State, PIN Code',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tax Information card
              _FormCard(
                title: 'Tax Information',
                children: [
                  _FormField(
                    label: 'GSTIN (optional)',
                    controller: controller.gstinController,
                    hint: '22AAAAA0000A1Z5',
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Obx(() => GestureDetector(
                    onTap: controller.save,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          controller.isEditing.value
                              ? 'UPDATE CLIENT'
                              : 'SAVE CLIENT',
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormCard({required this.title, required this.children});

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
          Text(title,
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const Divider(height: 20, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
      ),
      validator: validator ??
          (required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null),
    );
  }
}
