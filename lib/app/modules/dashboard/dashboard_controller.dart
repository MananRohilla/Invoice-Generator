import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/models/invoice_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/services/hive_service.dart';

class DashboardController extends GetxController {
  final totalRevenue = 0.0.obs;
  final totalClients = 0.obs;
  final pendingAmount = 0.0.obs;
  final overdueCount = 0.obs;
  final recentInvoices = <InvoiceModel>[].obs;
  final userProfile = Rxn<UserProfileModel>();

  // GlobalKeys for tutorial overlay
  static final statsKey = GlobalKey();
  static final quickActionsKey = GlobalKey();
  static final recentInvoicesKey = GlobalKey();
  static final fabKey = GlobalKey();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  @override
  void onReady() {
    super.onReady();
    _checkTutorial();
  }

  void loadData() {
    userProfile.value = HiveService.getProfile();
    totalRevenue.value = HiveService.getTotalRevenue();
    totalClients.value = HiveService.getAllClients().length;
    pendingAmount.value = HiveService.getTotalPending();
    overdueCount.value = HiveService.getOverdueCount();

    final all = HiveService.getAllInvoices();
    recentInvoices.assignAll(all.take(5).toList());
  }

  void _checkTutorial() {
    if (GetStorage().read('tutorialShown') != true) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (Get.isRegistered<TutorialController>()) {
          Get.find<TutorialController>().startTutorial();
        }
      });
    }
  }

  String get greeting {
    final hour = DateTime.now().hour;
    String time;
    if (hour < 12) {
      time = 'Good Morning';
    } else if (hour < 17) {
      time = 'Good Afternoon';
    } else {
      time = 'Good Evening';
    }
    final name = userProfile.value?.googleDisplayName?.split(' ').first ??
        userProfile.value?.businessName.split(' ').first ??
        'there';
    return '$time, $name';
  }

  String clientName(String clientId) =>
      HiveService.getClient(clientId)?.name ?? 'Unknown';
}

class TutorialController extends GetxController {
  final currentStep = (-1).obs;
  final isVisible = false.obs;

  static const steps = [
    _TutorialStep(
      title: 'Revenue Overview',
      description: 'See your total revenue, active clients, pending and overdue invoices at a glance.',
    ),
    _TutorialStep(
      title: 'Quick Actions',
      description: 'Tap here to quickly create invoices or add new clients in seconds.',
    ),
    _TutorialStep(
      title: 'Recent Activity',
      description: 'Your latest invoices appear here. Tap any to view details.',
    ),
    _TutorialStep(
      title: 'AI Assistant',
      description: 'Tap the chat button anytime to ask InvoGen AI for help.',
    ),
  ];

  void startTutorial() {
    currentStep.value = 0;
    isVisible.value = true;
  }

  void nextStep() {
    if (currentStep.value < steps.length - 1) {
      currentStep.value++;
    } else {
      completeTutorial();
    }
  }

  void completeTutorial() {
    isVisible.value = false;
    currentStep.value = -1;
    GetStorage().write('tutorialShown', true);
  }
}

class _TutorialStep {
  final String title;
  final String description;
  const _TutorialStep({required this.title, required this.description});
}
