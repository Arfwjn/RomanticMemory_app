import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../controllers/memory_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/memory_card.dart';
import '../utils/constants.dart';
import 'add_memory_screen.dart';
import 'memory_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final memoryController = Get.put(MemoryController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OUR TIMELINE',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Memories ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  TextSpan(
                    text: 'favorite',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: TextField(
              onChanged: memoryController.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Find a moment...',
                hintStyle: const TextStyle(color: AppColors.lightText),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: const Icon(Icons.tune, color: AppColors.lightText),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Obx(() => FilterChip(
                  label: const Text('All'),
                  selected: memoryController.selectedFilter.value == 'all',
                  onSelected: (selected) {
                    if (selected) memoryController.setFilter('all');
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: memoryController.selectedFilter.value == 'all'
                        ? Colors.white
                        : AppColors.darkText,
                  ),
                )),
                const SizedBox(width: AppSpacing.sm),
                Obx(() => FilterChip(
                  label: const Text('Favorites'),
                  selected: memoryController.selectedFilter.value == 'favorites',
                  onSelected: (selected) {
                    if (selected) memoryController.setFilter('favorites');
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: memoryController.selectedFilter.value == 'favorites'
                        ? Colors.white
                        : AppColors.darkText,
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Memories Grid
          Expanded(
            child: Obx(() {
              if (memoryController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (memoryController.filteredMemories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 48,
                        color: AppColors.lightText,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'No memories yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mediumText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Create your first memory',
                        style: TextStyle(
                          color: AppColors.lightText,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  itemCount: memoryController.filteredMemories.length,
                  itemBuilder: (context, index) {
                    final memory = memoryController.filteredMemories[index];
                    return MemoryCard(
                      memory: memory,
                      onTap: () {
                        Get.to(() => MemoryDetailScreen(memory: memory));
                      },
                      onFavoriteTap: () {
                        memoryController.toggleFavorite(
                          memory.id,
                          memory.isFavorite,
                        );
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const AddMemoryScreen());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
