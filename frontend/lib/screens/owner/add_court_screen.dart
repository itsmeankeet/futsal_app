import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/booking_provider.dart';
import '../../models/futsal.dart';

class AddCourtScreen extends ConsumerStatefulWidget {
  const AddCourtScreen({super.key});

  @override
  ConsumerState<AddCourtScreen> createState() => _AddCourtScreenState();
}

class _AddCourtScreenState extends ConsumerState<AddCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  Futsal? _selectedFutsal;
  bool _isIndoor = true;

  // Image Selection States
  final List<Uint8List?> _imageBytes = List.filled(4, null);
  final List<String?> _imageNames = List.filled(4, null);
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchFutsals(); // load owner's futsals
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes[index] = bytes;
          _imageNames[index] = file.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageBytes[index] = null;
      _imageNames[index] = null;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFutsal == null) {
      if (_selectedFutsal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a futsal arena first.'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    final imageFiles = <Map<String, dynamic>>[];
    for (int i = 0; i < 4; i++) {
      if (_imageBytes[i] != null && _imageNames[i] != null) {
        imageFiles.add({
          'bytes': _imageBytes[i],
          'name': _imageNames[i],
        });
      }
    }

    try {
      await ref.read(bookingProvider.notifier).createCourt(
            futsalId: _selectedFutsal!.id,
            name: _nameController.text.trim(),
            isIndoor: _isIndoor,
            pricePerHour: double.parse(_priceController.text.trim()),
            description: _descController.text.trim(),
            imageFiles: imageFiles,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Court added successfully!'),
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
        title: Text('Add Futsal Court', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: state.isLoading && state.futsals.isEmpty
          ? const Center(child: SpinKitFadingCircle(color: themeColor, size: 50))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Futsal Dropdown Selector
                    DropdownButtonFormField<Futsal>(
                      value: _selectedFutsal,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Select Futsal Arena',
                        prefixIcon: Icon(Icons.business, color: themeColor),
                      ),
                      items: state.futsals.map((futsal) {
                        return DropdownMenuItem<Futsal>(
                          value: futsal,
                          child: Text(futsal.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedFutsal = val;
                        });
                      },
                      validator: (val) => val == null ? 'Selection required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Court Name (e.g. Pitch A, Court 1)',
                        prefixIcon: Icon(Icons.sports_soccer, color: themeColor),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter court name' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Price Per Hour (Rs.)',
                        prefixIcon: Icon(Icons.monetization_on_outlined, color: themeColor),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter price per hour';
                        if (double.tryParse(val) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Court Description (dimensions, floor type...)',
                        prefixIcon: Icon(Icons.description_outlined, color: themeColor),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Court Photos Section
                    Text(
                      'Court Photos (Add up to 4 photos)',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final bytes = _imageBytes[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[850]!),
                          ),
                          child: bytes != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        bytes,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.black.withOpacity(0.6),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : InkWell(
                                  onTap: () => _pickImage(index),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_outlined, color: themeColor, size: 28),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Photo ${index + 1}',
                                        style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Pitch Type Toggle
                    Text(
                      'Pitch Specification',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isIndoor = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isIndoor ? themeColor.withOpacity(0.2) : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _isIndoor ? themeColor : Colors.transparent),
                              ),
                              child: Center(
                                child: Text(
                                  'Indoor (Wooden/Rubber)',
                                  style: GoogleFonts.inter(
                                    color: _isIndoor ? themeColor : Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isIndoor = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isIndoor ? themeColor.withOpacity(0.2) : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: !_isIndoor ? themeColor : Colors.transparent),
                              ),
                              child: Center(
                                child: Text(
                                  'Outdoor (Turf)',
                                  style: GoogleFonts.inter(
                                    color: !_isIndoor ? themeColor : Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                            : const Text('Add Court'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
