import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../modules/clients/client_controller.dart';
import '../../routes/app_routes.dart';

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ClientController>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => c.isSearching.value
            ? TextField(
                controller: c.searchController,
                autofocus: true,
                onChanged: (v) => c.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Search clients...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: cs.outline),
                ),
                style: TextStyle(color: cs.onSurface, fontSize: 16),
              )
            : const Text('Clients')),
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                    c.isSearching.value ? Icons.close : Icons.search_rounded),
                onPressed: c.toggleSearch,
              )),
        ],
      ),
      body: Obx(() {
        if (c.filteredClients.isEmpty) {
          return _EmptyState(
            isFiltered: c.searchQuery.value.isNotEmpty,
            onAdd: c.goToAdd,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: c.filteredClients.length,
          itemBuilder: (_, i) {
            final client = c.filteredClients[i];
            return Dismissible(
              key: Key(client.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 24),
              ),
              confirmDismiss: (_) async {
                return await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('Delete Client',
                        style: TextStyle(fontFamily: 'NotoSans')),
                    content: Text(
                        'Are you sure you want to delete ${client.name}?',
                        style: const TextStyle(fontFamily: 'NotoSans')),
                    actions: [
                      TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('Delete',
                              style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                );
              },
              onDismissed: (_) => c.deleteClient(client.id),
              child: _ClientCard(
                client: client,
                invoiceCount: c.invoiceCountForClient(client.id),
                onTap: () => c.goToDetail(client),
                onEdit: () => c.goToEdit(client),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.toNamed(AppRoutes.addClient);
          c.loadClients();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Client',
            style: TextStyle(
                fontFamily: 'NotoSans',
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final dynamic client;
  final int invoiceCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ClientCard({
    required this.client,
    required this.invoiceCount,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF34A853),
      const Color(0xFFF9AB00),
      AppColors.danger,
    ];
    final colorIndex = client.name.codeUnits.isNotEmpty
        ? client.name.codeUnits.first % colors.length
        : 0;
    final avatarColor = colors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 0.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: avatarColor,
                  child: Text(
                    client.initials,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.name,
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          )),
                      const SizedBox(height: 2),
                      Text(client.email,
                          style: const TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          )),
                      if (client.phone.isNotEmpty)
                        Text(client.phone,
                            style: const TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            )),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$invoiceCount',
                        style: const TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onEdit,
                      child: const Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onAdd;
  const _EmptyState({required this.isFiltered, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No clients found' : 'No clients yet',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try a different search term'
                  : 'Add your first client to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Client'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
