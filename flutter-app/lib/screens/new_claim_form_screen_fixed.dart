import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';

class NewClaimFormScreen extends StatefulWidget {
  const NewClaimFormScreen({Key? key}) : super(key: key);

  @override
  State<NewClaimFormScreen> createState() => _NewClaimFormScreenState();
}

class _NewClaimFormScreenState extends State<NewClaimFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();
  final _locationController = TextEditingController();
  final _damageDescriptionController = TextEditingController();
  
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _aadharController.dispose();
    _locationController.dispose();
    _damageDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('submit_claim'.tr()),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.assignment,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'new_claim'.tr(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'fill_details_below'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Aadhar Number Field - FIXED: Removed bottom overflow
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _aadharController,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: 'aadhar_number'.tr(),
                      hintText: 'enter_aadhar_number'.tr(),
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1E3C72),
                          width: 2,
                        ),
                      ),
                      // FIXED: Remove counter to prevent overflow
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please_enter_aadhar'.tr();
                      }
                      if (value.length != 12) {
                        return 'aadhar_must_be_12_digits'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                
                // Location Field
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'location'.tr(),
                      hintText: 'enter_location_or_get_current'.tr(),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: IconButton(
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1E3C72),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please_enter_location'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                
                // Damage Description Field
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: TextFormField(
                    controller: _damageDescriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'damage_description'.tr(),
                      hintText: 'describe_crop_damage'.tr(),
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1E3C72),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please_describe_damage'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                
                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitClaim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'submit_claim'.tr(), // FIXED: Now in chosen language
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20), // Extra padding at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FIXED: Location method with proper mounted checks
  Future<void> _getCurrentLocation() async {
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _locationController.text = 'Location permission denied';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationController.text = 'Location permission permanently denied';
          });
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return; // Check again before setState

      setState(() {
        _currentPosition = position;
        _locationController.text = 
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() {
          _locationController.text = 'Unable to get location: ${e.toString()}';
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _submitClaim() {
    if (_formKey.currentState!.validate()) {
      // Show success message in chosen language
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('claim_submitted_successfully'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back
      Navigator.of(context).pop();
    }
  }
}
