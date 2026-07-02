import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/booking_provider.dart';

class RegisterFutsalScreen extends ConsumerStatefulWidget {
  const RegisterFutsalScreen({super.key});

  @override
  ConsumerState<RegisterFutsalScreen> createState() => _RegisterFutsalScreenState();
}

class _RegisterFutsalScreenState extends ConsumerState<RegisterFutsalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  TimeOfDay _openingTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);

  final List<String> _selectedFacilityIds = [];

  // Image Selection States
  Uint8List? _logoBytes;
  String? _logoName;
  Uint8List? _coverBytes;
  String? _coverName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchFacilities();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _logoBytes = bytes;
          _logoName = file.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking logo: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _pickCover() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _coverBytes = bytes;
          _coverName = file.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking cover: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _selectTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF39FF14),
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hr = tod.hour.toString().padLeft(2, '0');
    final min = tod.minute.toString().padLeft(2, '0');
    return "$hr:$min:00";
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_coverBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cover image for your futsal arena.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await ref.read(bookingProvider.notifier).createFutsal(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            openingHours: _formatTimeOfDay(_openingTime),
            closingHours: _formatTimeOfDay(_closingTime),
            description: _descController.text.trim(),
            latitude: double.tryParse(_latitudeController.text.trim()) ?? 0.0,
            longitude: double.tryParse(_longitudeController.text.trim()) ?? 0.0,
            logoBytes: _logoBytes,
            logoName: _logoName,
            coverImageBytes: _coverBytes,
            coverImageName: _coverName,
            facilityIds: _selectedFacilityIds,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Futsal registered successfully! Pending Admin verification.'),
            backgroundColor: Color(0xFF39FF14),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    const themeColor = Color(0xFF39FF14);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Register Futsal Arena', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: state.isLoading && state.facilities.isEmpty
          ? const Center(child: SpinKitFadingCircle(color: themeColor, size: 50))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Visual Image Selection Section
                    Text(
                      'Futsal Visual Branding',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Cover Image Picker
                        GestureDetector(
                          onTap: _pickCover,
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[850]!),
                            ),
                            child: _coverBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      _coverBytes!,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_outlined, color: themeColor, size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Select Cover Photo (Required)',
                                        style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        // Logo Picker positioned on top of cover image
                        Positioned(
                          bottom: -30,
                          left: 20,
                          child: GestureDetector(
                            onTap: _pickLogo,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF262626),
                                shape: BoxShape.circle,
                                border: Border.all(color: themeColor, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _logoBytes != null
                                  ? ClipOval(
                                      child: Image.memory(
                                        _logoBytes!,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.grey,
                                      size: 28,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),

                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Futsal Business Name',
                        prefixIcon: Icon(Icons.sports_soccer, color: themeColor),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter business name' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Full Address',
                        prefixIcon: Icon(Icons.location_on_outlined, color: themeColor),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter address' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Contact Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined, color: themeColor),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter contact number' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Latitude (e.g. 27.68)',
                              prefixIcon: Icon(Icons.map_outlined, color: themeColor),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter latitude';
                              if (double.tryParse(val) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Longitude (e.g. 85.31)',
                              prefixIcon: Icon(Icons.map_outlined, color: themeColor),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter longitude';
                              if (double.tryParse(val) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Futsal Description (pitch size, flooring, special packages...)',
                        prefixIcon: Icon(Icons.description_outlined, color: themeColor),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter a description about the futsal' : null,
                    ),
                    const SizedBox(height: 24),

                    // Operating Hours Title
                    Text(
                      'Operating Hours',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Opening Time', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _openingTime.format(context),
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Closing Time', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _closingTime.format(context),
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Facilities Title
                    Text(
                      'Facilities Checklist',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),

                    // Facilities ListView/Wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.facilities.map((facility) {
                        final isSelected = _selectedFacilityIds.contains(facility.id);
                        return ChoiceChip(
                          label: Text(facility.name),
                          selected: isSelected,
                          selectedColor: themeColor.withOpacity(0.2),
                          checkmarkColor: themeColor,
                          labelStyle: GoogleFonts.inter(
                            color: isSelected ? themeColor : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? themeColor : Colors.transparent),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFacilityIds.add(facility.id);
                              } else {
                                _selectedFacilityIds.remove(facility.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: state.isLoading
                            ? const SpinKitThreeBounce(color: Colors.black, size: 24)
                            : const Text('Submit for Verification'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
