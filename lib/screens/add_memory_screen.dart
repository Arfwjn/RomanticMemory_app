import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../controllers/memory_controller.dart';
// import '../controllers/auth_controller.dart'; // Hapus atau comment jika belum ada
import '../models/memory.dart';
import '../services/audio_service.dart';
import '../services/location_service.dart';
import '../services/database_service.dart'; // Ganti ke DatabaseService
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({Key? key}) : super(key: key);

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final formKey = GlobalKey<FormState>();
  final imagePicker = ImagePicker();
  final databaseService = DatabaseService(); // Ganti ke DatabaseService
  final memoryController = Get.find<MemoryController>();
  // final authController = Get.find<AuthController>(); // Comment dulu

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController locationController;

  File? selectedImage;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? recordingPath;
  String? currentLocation;
  bool isRecording = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    dateController = TextEditingController();
    timeController = TextEditingController();
    locationController = TextEditingController();
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
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
          locationController.text = currentLocation ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _startRecording() async {
    final started = await AudioService.startRecording();
    if (started) {
      setState(() => isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    recordingPath = await AudioService.stopRecording();
    setState(() => isRecording = false);
  }

  Future<void> _saveMemory() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      // Simpan path lokal saja, tidak perlu upload ke Firebase
      String? imageUrl = selectedImage?.path;
      String? audioUrl = recordingPath;

      double? latitude;
      double? longitude;

      // Opsional: Validasi lokasi jika perlu
      if (currentLocation != null && currentLocation!.isNotEmpty) {
        try {
          final latLng =
              await LocationService.getCoordinatesFromAddress(currentLocation!);
          latitude = latLng?.latitude;
          longitude = latLng?.longitude;
        } catch (e) {
          print("Location coordinate error: $e");
        }
      }

      final dateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final memory = Memory(
        userId: 'local_user', // Hardcode user id untuk lokal
        title: titleController.text,
        description: descriptionController.text,
        imageUrl: imageUrl,
        date: dateTime,
        location: currentLocation,
        latitude: latitude,
        longitude: longitude,
        audioUrl: audioUrl,
      );

      await databaseService.createMemory(memory);
      memoryController.loadMemories();

      Get.back();
      Get.snackbar('Success', 'Memory saved successfully!',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Error saving memory: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isSaving = false);
    }
  }

  // ... (Sisa kode Dispose dan Build UI tetap sama seperti file asli Anda)
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
    // ... Copy paste bagian build dari file asli Anda di sini ...
    // Pastikan import di atas sudah benar. Kode UI Anda tidak perlu diubah signifikan.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // ... kode appbar sama ...
        title: const Text('New Memory',
            style: TextStyle(color: AppColors.darkText)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
            onPressed: () => Get.back()),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bagian Photo
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 240,
                    width: double.infinity, // Tambahkan width infinity
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.secondary, width: 2),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child:
                                Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 32),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const Text('Tap to Add Photo',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkText)),
                            ],
                          ),
                  ),
                ),
                // ... Sisa UI sama persis dengan kode Anda ...
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                    label: 'Memory Title',
                    hint: 'e.g., Sunset',
                    controller: titleController,
                    validator: Validators.validateTitle),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                    label: 'Tell your story',
                    hint: 'Share the story...',
                    controller: descriptionController,
                    maxLines: 4,
                    minLines: 3,
                    validator: Validators.validateDescription),
                const SizedBox(height: AppSpacing.lg),
                // Date logic... (sama)
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
                // Location and Audio UI logic... (sama)
                const SizedBox(height: AppSpacing.lg),
                GestureDetector(
                  onTap: isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                    decoration: BoxDecoration(
                        color: isRecording
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Row(children: [
                      Icon(isRecording ? Icons.stop : Icons.mic,
                          color: AppColors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Text(isRecording ? 'Stop Recording' : 'Record Voice Note')
                    ]),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                    label: 'Save Forever',
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
