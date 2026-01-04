import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/memory.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../services/audio_service.dart';
import '../controllers/memory_controller.dart';
import 'edit_memory_screen.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;

  const MemoryDetailScreen({
    Key? key,
    required this.memory,
  }) : super(key: key);

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final memoryController = Get.find<MemoryController>();
  bool isPlayingAudio = false;
  Duration audioPosition = Duration.zero;
  Duration audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.memory.audioUrl != null) {
      AudioService.getDurationStream().listen((duration) {
        setState(() => audioDuration = duration);
      });
      AudioService.getPositionStream().listen((position) {
        setState(() => audioPosition = position);
      });
    }
  }

  Future<void> _toggleAudio() async {
    if (isPlayingAudio) {
      await AudioService.pauseAudio();
    } else {
      await AudioService.playAudio(widget.memory.audioUrl!);
    }
    setState(() => isPlayingAudio = !isPlayingAudio);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              memoryController.deleteMemory(widget.memory.id);
              Get.back();
              Get.back();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memory deleted')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () {
              Get.to(() => EditMemoryScreen(memory: widget.memory));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (widget.memory.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.xl),
                  bottomRight: Radius.circular(AppRadius.xl),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.memory.imageUrl!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 300,
                width: double.infinity,
                color: AppColors.lightPink,
                child: const Icon(Icons.image, size: 48),
              ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.memory.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Date & Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        DateFormatter.formatDate(widget.memory.date),
                        style: const TextStyle(
                          color: AppColors.mediumText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.schedule,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        DateFormatter.formatTime(widget.memory.date),
                        style: const TextStyle(
                          color: AppColors.mediumText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Location
                  if (widget.memory.location != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Where',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.darkText),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(widget.memory.location!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),

                  // Description
                  const Text(
                    'Story',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      widget.memory.description,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Audio Player
                  if (widget.memory.audioUrl != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voice Note',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.lightOrange,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: _toggleAudio,
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                          AppSpacing.md),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPlayingAudio
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.sm),
                                            child: LinearProgressIndicator(
                                              value: audioDuration.inMilliseconds
                                                      > 0
                                                  ? audioPosition.inMilliseconds /
                                                      audioDuration
                                                          .inMilliseconds
                                                  : 0,
                                              backgroundColor:
                                                  Colors.white.withOpacity(0.5),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(AppColors.primary),
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppSpacing.xs),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDuration(audioPosition),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.darkText,
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(audioDuration),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.darkText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),

                  // Favorite Button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        memoryController.toggleFavorite(
                          widget.memory.id,
                          widget.memory.isFavorite,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: widget.memory.isFavorite
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.memory.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.memory.isFavorite
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Add to Favorites',
                              style: TextStyle(
                                color: widget.memory.isFavorite
                                    ? Colors.white
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
