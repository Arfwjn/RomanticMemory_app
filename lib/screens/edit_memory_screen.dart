import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/memory.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/memory_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class EditMemoryScreen extends StatefulWidget {
  final Memory memory;

  const EditMemoryScreen({
    Key? key,
    required this.memory,
  }) : super(key: key);

  @override
  State<EditMemoryScreen> createState() => _EditMemoryScreenState();
}

class _EditMemoryScreenState extends State<EditMemoryScreen> {
  final formKey = GlobalKey<FormState>();
  final imagePicker = ImagePicker();
  final firebaseService = FirebaseService();
  final memoryController = Get.find<MemoryController>();
  final authController = Get.find<AuthController>();

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController locationController;

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
  }

  Future<void> _saveMemory() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      String? imageUrl = widget.memory.imageUrl;

      // Upload new image if selected
      if (selectedImage != null) {
        imageUrl = await firebaseService.uploadImage(
          selectedImage!.path,
          authController.currentUser.value!.id,
        );
      }

      // Get coordinates if location changed
      double? latitude = widget.memory.latitude;
      double? longitude = widget.memory.longitude;
      if (currentLocation != null &&
          currentLocation != widget.memory.location) {
        final latLng =
            await LocationService.getCoordinatesFromAddress(currentLocation!);
        latitude = latLng?.latitude;
        longitude = latLng?.longitude;
      }

      // Combine date and time
      final dateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // Create updated memory
      final updatedMemory = widget.memory.copyWith(
        title: titleController.text,
        description: descriptionController.text,
        imageUrl: imageUrl,
        date: dateTime,
        location: currentLocation,
        latitude: latitude,
        longitude: longitude,
      );

      await firebaseService.updateMemory(updatedMemory);
      memoryController.loadMemories();

      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating memory: $e')),
      );
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
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Edit Memory',
          style: TextStyle(color: AppColors.darkText),
        ),
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
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 2,
                      ),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : widget.memory.imageUrl != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                child: Image.network(
                                  widget.memory.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  const Text(
                                    'Tap to Change Photo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                CustomTextField(
                  label: 'Memory Title',
                  controller: titleController,
                  validator: Validators.validateTitle,
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                CustomTextField(
                  label: 'Tell your story',
                  controller: descriptionController,
                  maxLines: 4,
                  minLines: 3,
                  validator: Validators.validateDescription,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Date & Time
                const Text(
                  'When was this?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                dateController.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule,
                                  color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                timeController.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Location
                const Text(
                  'Where were you?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _getCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on,
                                  color: AppColors.darkText, size: 20),
                              SizedBox(height: AppSpacing.sm),
                              Text('Current Spot',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (currentLocation != null)
                  Text(
                    'Location: $currentLocation',
                    style: const TextStyle(
                      color: AppColors.mediumText,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),

                // Save Button
                CustomButton(
                  label: 'Save Changes',
                  onPressed: _saveMemory,
                  isLoading: isSaving,
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
