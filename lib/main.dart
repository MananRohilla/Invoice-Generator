import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/bindings/app_bindings.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/models/client_model.dart';
import 'app/data/models/invoice_item_model.dart';
import 'app/data/models/invoice_model.dart';
import 'app/data/models/user_profile_model.dart';
import 'app/data/services/hive_service.dart';
import 'app/modules/theme/theme_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

Future<void> _initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ClientModelAdapter());
  Hive.registerAdapter(InvoiceItemModelAdapter());
  Hive.registerAdapter(InvoiceModelAdapter());
  Hive.registerAdapter(UserProfileModelAdapter());
  await HiveService.init();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  try {
    await _initHive();
  } catch (_) {
    // Corrupted boxes — wipe and re-init cleanly
    await Hive.deleteFromDisk();
    await _initHive();
  }

  await GetStorage.init();
  Get.put<ThemeController>(ThemeController(), permanent: true);

  runApp(const InvoGenApp());
}

class InvoGenApp extends StatelessWidget {
  const InvoGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Obx(() => GetMaterialApp(
          title: 'InvoGen',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeCtrl.themeMode.value,
          initialBinding: AppBindings(),
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,
        ));
  }
}
