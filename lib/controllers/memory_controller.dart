import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../models/memory.dart';

class MemoryController extends GetxController {
  final firebaseService = FirebaseService();
  
  final memories = <Memory>[].obs;
  final filteredMemories = <Memory>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'all'.obs; // all, favorites

  late String userId;

  @override
  void onInit() {
    super.onInit();
    userId = firebaseService.getCurrentUserId() ?? '';
    loadMemories();
  }

  void loadMemories() {
    isLoading(true);
    firebaseService.getUserMemoriesStream(userId).listen((data) {
      memories.assignAll(data);
      applyFilters();
      isLoading(false);
    });
  }

  void applyFilters() {
    var filtered = memories.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where((m) =>
              m.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
              m.description.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    // Apply favorites filter
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
    await firebaseService.toggleFavorite(memoryId, !currentState);
  }

  Future<void> deleteMemory(String memoryId) async {
    await firebaseService.deleteMemory(memoryId);
  }
}
