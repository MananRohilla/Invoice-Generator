import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  static const _key = 'themeMode';

  final themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    final stored = _box.read<String>(_key);
    if (stored == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (stored == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.system;
    }
  }

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
    switch (mode) {
      case ThemeMode.light:
        _box.write(_key, 'light');
      case ThemeMode.dark:
        _box.write(_key, 'dark');
      case ThemeMode.system:
        _box.write(_key, 'system');
    }
    Get.changeThemeMode(mode);
  }
}
