import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  void _navigate() {
    final box = GetStorage();
    if (box.read('isLoggedIn') == true) {
      Get.offAllNamed(AppRoutes.shell);
    } else if (box.read('isFirstLaunch') != false) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
