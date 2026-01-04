import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/memory.dart';
import '../services/database_service.dart'; // Ubah import
import '../services/location_service.dart';
// import '../controllers/auth_controller.dart'; // Hapus
import '../controllers/memory_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class EditMemoryScreen extends StatefulWidget {
  final Memory memory;
  const EditMemoryScreen({Key? key, required this.memory}) : super(key: key);

  @override
  State<EditMemoryScreen> createState() => _EditMemoryScreenState();
}

class _EditMemoryScreenState extends State<EditMemoryScreen> {
  final formKey = GlobalKey<FormState>();
  final imagePicker = ImagePicker();
  final databaseService = DatabaseService(); // Ganti Service
  final memoryController = Get.find<MemoryController>();

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  // late TextEditingController locationController; // (Tampaknya tidak dipakai di build, tapi di-init)

  File? selectedImage;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? currentLocation;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.memory.title);
    descriptionController =
        TextEditingController(text: widget.memory.description);
    selectedDate = widget.memory.date;
    selectedTime = TimeOfDay.fromDateTime(widget.memory.date);
    currentLocation = widget.memory.location;
    _updateDateTimeControllers();
  }

  void _updateDateTimeControllers() {
    if (selectedDate != null) {
      dateController.text = DateFormat('MMM d, yyyy').format(selectedDate!);
    }
    if (selectedTime != null) {
      timeController.text = selectedTime!.format(context);
    }
  }

  Future<void> _pickImage() async {
    final picked = await imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _updateDateTimeControllers();
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        _updateDateTimeControllers();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        setState(() {
          currentLocation = address ?? 'Location set';
        });
      }
    } catch (e) {
      print("Error location: $e");
    }
  }

  Future<void> _saveMemory() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSaving = true);

    try {
      // Logic lokal: gunakan path file baru jika ada, jika tidak pakai yang lama
      String? imageUrl =
          selectedImage != null ? selectedImage!.path : widget.memory.imageUrl;

      double? latitude = widget.memory.latitude;
      double? longitude = widget.memory.longitude;

      // Update koordinat jika lokasi berubah string-nya
      if (currentLocation != null &&
          currentLocation != widget.memory.location) {
        try {
          final latLng =
              await LocationService.getCoordinatesFromAddress(currentLocation!);
          latitude = latLng?.latitude;
          longitude = latLng?.longitude;
        } catch (_) {}
      }

      final dateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final updatedMemory = widget.memory.copyWith(
        title: titleController.text,
        description: descriptionController.text,
        imageUrl: imageUrl,
        date: dateTime,
        location: currentLocation,
        latitude: latitude,
        longitude: longitude,
      );

      await databaseService.updateMemory(updatedMemory);
      memoryController.loadMemories();

      Get.back();
      Get.snackbar('Success', 'Memory updated!',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Error: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return UI Code (copy dari file original, bagian Image logic perlu penyesuaian sedikit)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
            onPressed: () => Get.back()),
        title: const Text('Edit Memory',
            style: TextStyle(color: AppColors.darkText)),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.secondary, width: 2),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child:
                                Image.file(selectedImage!, fit: BoxFit.cover))
                        : widget.memory.imageUrl != null &&
                                widget.memory.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                // PENTING: Gunakan Image.file karena data lokal
                                child: Image.file(File(widget.memory.imageUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => const Center(
                                        child: Icon(Icons.broken_image,
                                            size: 40, color: Colors.grey))),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.md),
                                      decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 32)),
                                  const SizedBox(height: AppSpacing.md),
                                  const Text('Tap to Change Photo',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkText)),
                                ],
                              ),
                  ),
                ),
                // ... Sisa UI copy paste dari file asli ...
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                    label: 'Memory Title',
                    controller: titleController,
                    validator: Validators.validateTitle),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                    label: 'Tell your story',
                    controller: descriptionController,
                    maxLines: 4,
                    minLines: 3,
                    validator: Validators.validateDescription),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                          child: Row(children: [
                            const Icon(Icons.calendar_today,
                                color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(dateController.text)
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                          child: Row(children: [
                            const Icon(Icons.schedule,
                                color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(timeController.text)
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                    label: 'Save Changes',
                    onPressed: _saveMemory,
                    isLoading: isSaving,
                    backgroundColor: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
