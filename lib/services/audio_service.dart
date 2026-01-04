import 'package:flutter/material.dart';
import 'dart:io';
import '../models/memory.dart';
import '../utils/constants.dart';

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;

  const MemoryCard({
    Key? key,
    required this.memory,
    required this.onTap,
    this.onFavoriteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [AppShadows.subtle],
          color: AppColors.cardBackground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Logic: Prioritaskan File Lokal
            if (memory.imageUrl != null && memory.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.file(
                  File(memory.imageUrl!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                height: 150, // Samakan tinggi
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: const Center(
                  child:
                      Icon(Icons.image, color: AppColors.lightText, size: 40),
                ),
              ),

            // Location badge
            if (memory.location != null && memory.location!.isNotEmpty)
              Padding(
                // Gunakan Padding/Row alih-alih Positioned jika tidak dalam Stack
                padding: const EdgeInsets.only(left: 12, top: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                          child: Text(memory.location!,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onFavoriteTap != null)
                        GestureDetector(
                          onTap: onFavoriteTap,
                          child: Icon(
                            memory.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(memory.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mediumText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
