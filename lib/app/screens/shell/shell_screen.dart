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
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: (i) {
              controller.changePage(i);
              // Refresh data when switching tabs
              if (i == 0) Get.find<DashboardController>().loadData();
              if (i == 1) Get.find<ClientController>().loadClients();
              if (i == 2) Get.find<InvoiceListController>().loadInvoices();
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
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
