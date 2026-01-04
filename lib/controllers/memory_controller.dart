import 'package:get/get.dart';
import '../services/database_service.dart'; // Ganti import
import '../models/memory.dart';

class MemoryController extends GetxController {
  final databaseService = DatabaseService(); // Gunakan DatabaseService

  final memories = <Memory>[].obs;
  final filteredMemories = <Memory>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'all'.obs;

  late String userId;

  @override
  void onInit() {
    super.onInit();
    // Untuk lokal, kita bisa pakai ID dummy jika Auth belum siap
    userId = 'local_user';
    loadMemories();
  }

  void loadMemories() async {
    isLoading(true);
    try {
      final data = await databaseService.getMemories(userId);
      memories.assignAll(data);
      applyFilters();
    } catch (e) {
      print("Error loading memories: $e");
    } finally {
      isLoading(false);
    }
  }

  void applyFilters() {
    var filtered = memories.toList();

    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where((m) =>
              m.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
              m.description
                  .toLowerCase()
                  .contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    if (selectedFilter.value == 'favorites') {
      filtered = filtered.where((m) => m.isFavorite).toList();
    }

    filteredMemories.assignAll(filtered);
  }

  void updateSearchQuery(String query) {
    searchQuery(query);
    applyFilters();
  }

  void setFilter(String filter) {
    selectedFilter(filter);
    applyFilters();
  }

  Future<void> toggleFavorite(String memoryId, bool currentState) async {
    // Optimistic update UI
    final index = memories.indexWhere((m) => m.id == memoryId);
    if (index != -1) {
      final updatedMemory = memories[index].copyWith(isFavorite: !currentState);
      memories[index] = updatedMemory;
      applyFilters();
    }

    await databaseService.toggleFavorite(memoryId, !currentState);
    loadMemories(); // Reload to ensure sync
  }

  Future<void> deleteMemory(String memoryId) async {
    await databaseService.deleteMemory(memoryId);
    loadMemories();
  }
}
