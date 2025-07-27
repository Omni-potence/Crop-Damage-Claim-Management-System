import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_event.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_state.dart';
import 'package:crop_damage_app/models/user.dart';
import 'package:crop_damage_app/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:easy_localization/easy_localization.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name if available from Firebase Auth (for Google Sign-In)
    final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
      _nameController.text = currentUser.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aadharController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us serve you better',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form Container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Full Name
            _buildInputField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Aadhar Number
            _buildInputField(
              label: 'Aadhar Number',
              controller: _aadharController,
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              maxLength: 12,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your Aadhar number';
                }
                if (value.length != 12) {
                  return 'Aadhar number must be 12 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Address
            _buildInputField(
              label: 'Address',
              controller: _addressController,
              icon: Icons.location_on,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                if (value.length < 10) {
                  return 'Please enter a complete address';
                }
                return null;
              },
            ),
            
            const Spacer(),
            
            // Complete Profile Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _completeProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Note about required fields
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete your profile to submit claims and track status',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade50,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(
                icon,
                color: Colors.green.shade600,
              ),
              counterText: maxLength != null ? '' : null,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  void _completeProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final user = User(
            id: currentUser.uid,
            name: _nameController.text.trim(),
            phone: '', // No phone number for email auth
            aadhar: _aadharController.text.trim(),
            address: _addressController.text.trim(),
            createdAt: Timestamp.now(),
          );

          await FirebaseService().createUserProfile(user);
          
          // Update auth state with complete user profile
          if (mounted) {
            context.read<AuthBloc>().add(ProfileCompleted(user));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }


}
