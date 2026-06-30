import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Role specific fields
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _panNumberController = TextEditingController();
  final _businessAddressController = TextEditingController();

  String _selectedRole = 'CUSTOMER'; // CUSTOMER or OWNER

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _selectedRole,
            phone: _selectedRole == 'CUSTOMER' ? _phoneController.text.trim() : null,
            companyName: _selectedRole == 'OWNER' ? _companyNameController.text.trim() : null,
            panNumber: _selectedRole == 'OWNER' ? _panNumberController.text.trim() : null,
            businessAddress: _selectedRole == 'OWNER' ? _businessAddressController.text.trim() : null,
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedRole == 'OWNER' 
                ? 'Owner registered! Access will be granted after Admin approval.' 
                : 'Registration successful! Please login.',
            ),
            backgroundColor: const Color(0xFF39FF14),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
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
    final authState = ref.watch(authProvider);
    const themeColor = Color(0xFF39FF14);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join Kickoff',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Select your role and build your profile',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),

                // Role Toggle Box
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'CUSTOMER'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'CUSTOMER'
                                ? themeColor.withOpacity(0.2)
                                : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'CUSTOMER' ? themeColor : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Customer',
                              style: GoogleFonts.inter(
                                color: _selectedRole == 'CUSTOMER' ? themeColor : Colors.grey[400],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'OWNER'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'OWNER'
                                ? themeColor.withOpacity(0.2)
                                : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'OWNER' ? themeColor : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Futsal Owner',
                              style: GoogleFonts.inter(
                                color: _selectedRole == 'OWNER' ? themeColor : Colors.grey[400],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Common Fields
                TextFormField(
                  controller: _usernameController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Username',
                    prefixIcon: Icon(Icons.person_outline, color: themeColor),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter username' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: themeColor),
                  ),
                  validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: themeColor),
                  ),
                  validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 16),

                // Role-Specific Fields
                if (_selectedRole == 'CUSTOMER') ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined, color: themeColor),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _companyNameController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Company Name',
                      prefixIcon: Icon(Icons.business_outlined, color: themeColor),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter company name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _panNumberController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'PAN Number (Optional)',
                      prefixIcon: Icon(Icons.assignment_outlined, color: themeColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessAddressController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Business Address',
                      prefixIcon: Icon(Icons.location_on_outlined, color: themeColor),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter business address' : null,
                  ),
                ],
                const SizedBox(height: 36),

                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: authState.isLoading
                        ? const SpinKitThreeBounce(color: Colors.black, size: 24)
                        : Text(
                            'Sign Up',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
