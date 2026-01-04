import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import '../models/memory.dart';

class MemoryController extends GetxController {
  final databaseService = DatabaseService();
  final firebaseService = FirebaseService();

  final memories = <Memory>[].obs;
  final filteredMemories = <Memory>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'all'.obs;

  late String userId;

  @override
  void onInit() {
    super.onInit();
    // Get user ID from Firebase Service
    userId = firebaseService.getCurrentUserId() ?? 'local_user';
    loadMemories();
  }

  /// Load all memories from database
  Future<void> loadMemories() async {
    isLoading(true);
    try {
      final data = await databaseService.getMemories(userId);
      memories.assignAll(data);
      applyFilters();
    } catch (e) {
      print("Error loading memories: $e");
      Get.snackbar(
        'Error',
        'Failed to load memories: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  /// Apply search and filter
  void applyFilters() {
    var filtered = memories.toList();

    // Apply search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where((m) =>
              m.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
              m.description
                  .toLowerCase()
                  .contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    // Apply filter (all/favorites)
    if (selectedFilter.value == 'favorites') {
      filtered = filtered.where((m) => m.isFavorite).toList();
    }

    filteredMemories.assignAll(filtered);
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery(query);
    applyFilters();
  }

  /// Set filter (all/favorites)
  void setFilter(String filter) {
    selectedFilter(filter);
    applyFilters();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String memoryId, bool currentState) async {
    try {
      // Optimistic UI update
      final index = memories.indexWhere((m) => m.id == memoryId);
      if (index != -1) {
        final updatedMemory =
            memories[index].copyWith(isFavorite: !currentState);
        memories[index] = updatedMemory;
        applyFilters();
      }

      // Update database
      await databaseService.toggleFavorite(memoryId, !currentState);

      // Reload to ensure sync
      loadMemories();
    } catch (e) {
      print("Error toggling favorite: $e");
      Get.snackbar(
        'Error',
        'Failed to update favorite status',
        snackPosition: SnackPosition.BOTTOM,
      );
      // Reload to restore correct state
      loadMemories();
    }
  }

  /// Delete memory
  Future<void> deleteMemory(String memoryId) async {
    try {
      await databaseService.deleteMemory(memoryId);
      loadMemories();

      Get.snackbar(
        'Success',
        'Memory deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("Error deleting memory: $e");
      Get.snackbar(
        'Error',
        'Failed to delete memory',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Get memory count
  Future<int> getMemoryCount() async {
    try {
      return await databaseService.getMemoriesCount(userId);
    } catch (e) {
      print("Error getting memory count: $e");
      return 0;
    }
  }

  /// Get favorite memories only
  Future<void> loadFavoriteMemories() async {
    try {
      final data = await databaseService.getFavoriteMemories(userId);
      filteredMemories.assignAll(data);
    } catch (e) {
      print("Error loading favorite memories: $e");
    }
  }

  /// Search memories
  Future<void> searchMemories(String query) async {
    try {
      if (query.isEmpty) {
        loadMemories();
        return;
      }

      isLoading(true);
      final data = await databaseService.searchMemories(userId, query);
      memories.assignAll(data);
      applyFilters();
    } catch (e) {
      print("Error searching memories: $e");
    } finally {
      isLoading(false);
    }
  }

  /// Refresh memories
  @override
  Future<void> refresh() async {
    await loadMemories();
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
