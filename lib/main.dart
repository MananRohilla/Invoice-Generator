import 'package:flutter/material.dart';
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
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ClientModelAdapter());
  Hive.registerAdapter(InvoiceItemModelAdapter());
  Hive.registerAdapter(InvoiceModelAdapter());
  Hive.registerAdapter(UserProfileModelAdapter());
  await HiveService.init();

  // Init GetStorage (for boolean flags only)
  await GetStorage.init();

  runApp(const InvoGenApp());
}

class InvoGenApp extends StatelessWidget {
  const InvoGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'InvoGen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
