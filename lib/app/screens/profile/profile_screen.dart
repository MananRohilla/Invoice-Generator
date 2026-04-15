import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../modules/profile/profile_controller.dart';
import '../../modules/theme/theme_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: controller.save,
            child: const Text('SAVE',
                style: TextStyle(
                    fontFamily: 'NotoSans',
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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

            // Logo picker — 96px
            Center(
              child: Obx(() {
                final path = controller.logoPath.value;
                return Column(
                  children: [
                    GestureDetector(
                      onTap: controller.pickLogo,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: path != null
                                ? FileImage(File(path))
                                : null,
                            child: path == null
                                ? const Icon(Icons.business_rounded,
                                    size: 48, color: AppColors.primary)
                                : null,
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to change logo',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 20),

            // Business Information
            _FormCard(
              title: 'Business Information',
              children: [
                _Field(
                    label: 'Business Name *',
                    controller: controller.businessNameController),
                const SizedBox(height: 14),
                TextFormField(
                  controller: controller.addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Business Address',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                _Field(
                    label: 'Email *',
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _Field(
                    label: 'Phone',
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone),
              ],
            ),

            const SizedBox(height: 12),

            // Tax Information
            _FormCard(
              title: 'Tax Information',
              children: [
                _Field(
                    label: 'GSTIN (optional)',
                    controller: controller.gstinController),
                const SizedBox(height: 14),
                Obx(() => DropdownButtonFormField<double>(
                      key: ValueKey(controller.selectedDefaultGst.value),
                      initialValue: controller.selectedDefaultGst.value,
                      decoration:
                          const InputDecoration(labelText: 'Default GST Rate'),
                      items: ProfileController.gstOptions
                          .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text('$g%',
                                  style: const TextStyle(
                                      fontFamily: 'NotoSans', fontSize: 14))))
                          .toList(),
                      onChanged: (v) =>
                          controller.selectedDefaultGst.value = v!,
                      style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface),
                    )),
              ],
            ),

            const SizedBox(height: 12),

            // Invoice Defaults
            _FormCard(
              title: 'Invoice Defaults',
              children: [
                Obx(() => DropdownButtonFormField<String>(
                      key: ValueKey(controller.selectedDefaultTerms.value),
                      initialValue: controller.selectedDefaultTerms.value,
                      decoration:
                          const InputDecoration(labelText: 'Default Terms'),
                      items: ProfileController.termOptions
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t,
                                  style: const TextStyle(
                                      fontFamily: 'NotoSans', fontSize: 14))))
                          .toList(),
                      onChanged: (v) =>
                          controller.selectedDefaultTerms.value = v!,
                      style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface),
                    )),
                const SizedBox(height: 14),
                TextFormField(
                  controller: controller.defaultNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Default Notes',
                    hintText: 'Thank you for your business!',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Appearance
            _FormCard(
              title: 'Appearance',
              children: [
                Obx(() {
                  final themeCtrl = Get.find<ThemeController>();
                  return SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {themeCtrl.themeMode.value},
                    onSelectionChanged: (s) => themeCtrl.setTheme(s.first),
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 12),

            // Account section
            _FormCard(
              title: 'Account',
              children: [
                Obx(() {
                  final p = controller.userProfile.value;
                  if (p == null) return const SizedBox.shrink();
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: p.googlePhotoUrl != null
                            ? NetworkImage(p.googlePhotoUrl!)
                            : null,
                        child: p.googlePhotoUrl == null
                            ? Text(
                                p.googleDisplayName?.isNotEmpty == true
                                    ? p.googleDisplayName![0]
                                    : 'U',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.googleDisplayName ?? 'User',
                              style: const TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            Text(p.email,
                                style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Sign Out',
                              style: TextStyle(fontFamily: 'NotoSans')),
                          content: const Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(fontFamily: 'NotoSans')),
                          actions: [
                            TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Get.back(result: true),
                                child: const Text('Sign Out',
                                    style: TextStyle(
                                        color: AppColors.danger))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await Future.delayed(Duration.zero);
                        controller.signOut();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Sign Out',
                        style: TextStyle(
                            fontFamily: 'NotoSans', fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
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
                  color: AppColors.textPrimary)),
          const Divider(height: 20, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _Field(
      {required this.label, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }
}
