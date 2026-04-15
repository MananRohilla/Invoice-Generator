import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../modules/clients/client_controller.dart';
import '../../modules/dashboard/dashboard_controller.dart';
import '../../modules/invoices/invoice_controller.dart';
import '../../modules/shell/shell_controller.dart';
import '../clients/client_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../invoices/invoice_list_screen.dart';
import '../profile/profile_screen.dart';

class ShellScreen extends GetView<ShellController> {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            DashboardScreen(),
            ClientListScreen(),
            InvoiceListScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.divider, width: 0.8),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            elevation: 0,
            backgroundColor: AppColors.surface,
            onTap: (i) {
              controller.changePage(i);
              if (i == 0) Get.find<DashboardController>().loadData();
              if (i == 1) Get.find<ClientController>().loadClients();
              if (i == 2) Get.find<InvoiceListController>().loadInvoices();
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_rounded),
                label: 'Clients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_outlined),
                activeIcon: Icon(Icons.receipt_rounded),
                label: 'Invoices',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      );
    });
  }
}
