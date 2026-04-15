import 'package:get/get.dart';

import '../modules/auth/auth_controller.dart';
import '../modules/clients/client_controller.dart';
import '../modules/dashboard/dashboard_controller.dart';
import '../modules/invoices/invoice_controller.dart';
import '../modules/onboarding/onboarding_controller.dart';
import '../modules/profile/profile_controller.dart';
import '../modules/reports/reports_controller.dart';
import '../modules/shell/shell_controller.dart';
import '../modules/splash/splash_controller.dart';
import '../screens/auth/login_screen.dart';
import '../screens/clients/add_client_screen.dart';
import '../screens/clients/client_detail_screen.dart';
import '../screens/invoices/create_invoice_screen.dart';
import '../screens/invoices/invoice_details_screen.dart';
import '../screens/invoices/invoice_preview_screen.dart';
import '../screens/invoices/pdf_viewer_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/shell/shell_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() => Get.put(SplashController())),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => OnboardingController())),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AuthController())),
    ),
    GetPage(
      name: AppRoutes.shell,
      page: () => const ShellScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ShellController());
        Get.lazyPut(() => DashboardController());
        Get.lazyPut(() => TutorialController());
        Get.lazyPut(() => ClientController());
        Get.lazyPut(() => InvoiceListController());
        Get.lazyPut(() => ProfileController());
      }),
    ),
    GetPage(
      name: AppRoutes.addClient,
      page: () => const AddClientScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AddClientController())),
    ),
    GetPage(
      name: AppRoutes.editClient,
      page: () => const AddClientScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AddClientController())),
    ),
    GetPage(
      name: AppRoutes.clientDetail,
      page: () => const ClientDetailScreen(),
    ),
    GetPage(
      name: AppRoutes.createInvoice,
      page: () => const CreateInvoiceScreen(),
      binding:
          BindingsBuilder(() => Get.lazyPut(() => CreateInvoiceController())),
    ),
    GetPage(
      name: AppRoutes.editInvoice,
      page: () => const CreateInvoiceScreen(),
      binding:
          BindingsBuilder(() => Get.lazyPut(() => CreateInvoiceController())),
    ),
    GetPage(
      name: AppRoutes.invoicePreview,
      page: () => const InvoicePreviewScreen(),
      binding: BindingsBuilder(
          () => Get.lazyPut(() => InvoicePreviewController())),
    ),
    GetPage(
      name: AppRoutes.invoiceDetails,
      page: () => const InvoiceDetailsScreen(),
      binding: BindingsBuilder(
          () => Get.lazyPut(() => InvoiceDetailsController())),
    ),
    GetPage(
      name: AppRoutes.pdfViewer,
      page: () => const PdfViewerScreen(),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ReportsController())),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ProfileController())),
    ),
  ];
}
