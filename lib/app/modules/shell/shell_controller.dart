import 'package:get/get.dart';

class ShellController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) => currentIndex.value = index;
}
