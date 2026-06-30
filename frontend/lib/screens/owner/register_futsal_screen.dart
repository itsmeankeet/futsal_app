import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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
  
  TimeOfDay _openingTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);

  final List<String> _selectedFacilityIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchFacilities();
    });
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

    try {
      await ref.read(bookingProvider.notifier).createFutsal(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            openingHours: _formatTimeOfDay(_openingTime),
            closingHours: _formatTimeOfDay(_closingTime),
            logo: 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?q=80&w=150&auto=format&fit=crop',
            coverImage: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=600&auto=format&fit=crop',
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
