import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop_damage_app/models/claim.dart';
import 'package:crop_damage_app/services/firebase_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_bloc.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_state.dart';

class NewClaimFormScreen extends StatefulWidget {
  const NewClaimFormScreen({super.key});

  @override
  State<NewClaimFormScreen> createState() => _NewClaimFormScreenState();
}

class _NewClaimFormScreenState extends State<NewClaimFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _landAddressController = TextEditingController();
  final TextEditingController _surveyKhasraNumberController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  
  String? _selectedDamageType;
  XFile? _cropPhoto;
  List<File> _supportingDocuments = [];
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLocationLoading = false;

  final List<String> _damageTypes = [
    'Drought',
    'Pest Attack',
    'Flood',
    'Hailstorm',
    'Disease',
    'Wild Animals',
    'Other'
  ];

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _landAddressController.dispose();
    _surveyKhasraNumberController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Submit New Claim'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Indicator
                    _buildProgressIndicator(),
                    const SizedBox(height: 24),
                    
                    // Crop Photo Section
                    _buildPhotoSection(),
                    const SizedBox(height: 24),
                    
                    // Damage Type Section
                    _buildDamageTypeSection(),
                    const SizedBox(height: 24),
                    
                    // Location Section
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    
                    // Land Details Section
                    _buildLandDetailsSection(),
                    const SizedBox(height: 24),
                    
                    // Supporting Documents Section
                    _buildDocumentsSection(),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Claim Submission',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Fill all required fields to submit your claim',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return _buildSection(
      title: 'Crop Photo',
      icon: Icons.camera_alt,
      required: true,
      child: Column(
        children: [
          if (_cropPhoto != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_cropPhoto!.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'From Gallery',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDamageTypeSection() {
    return _buildSection(
      title: 'Type of Damage',
      icon: Icons.warning,
      required: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedDamageType,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
            hintText: 'Select damage type',
          ),
          items: _damageTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedDamageType = newValue;
            });
          },
          validator: (value) => value == null ? 'Please select damage type' : null,
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildSection(
      title: 'GPS Location',
      icon: Icons.location_on,
      required: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentPosition != null ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _currentPosition != null ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentPosition != null ? Icons.check_circle : Icons.location_searching,
                  color: _currentPosition != null ? Colors.green.shade600 : Colors.orange.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPosition != null ? 'Location Captured' : 'Fetching Location...',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _currentPosition != null ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                      if (_currentPosition != null)
                        Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                          'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.refresh,
            label: _isLocationLoading ? 'Refreshing...' : 'Refresh Location',
            onPressed: _isLocationLoading ? null : _getCurrentLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildLandDetailsSection() {
    return _buildSection(
      title: 'Land Details',
      icon: Icons.landscape,
      required: true,
      child: Column(
        children: [
          _buildTextField(
            controller: _landAddressController,
            label: 'Land Address (Village, District)',
            hint: 'Enter complete address',
            validator: (value) => value!.isEmpty ? 'Please enter land address' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _surveyKhasraNumberController,
            label: 'Survey/Khasra Number',
            hint: 'Enter survey number',
            validator: (value) => value!.isEmpty ? 'Please enter survey/khasra number' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _areaController,
            label: 'Area (in acres)',
            hint: 'Enter area in acres',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value!.isEmpty) return 'Please enter area';
              if (double.tryParse(value) == null) return 'Please enter valid number';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return _buildSection(
      title: 'Supporting Documents',
      icon: Icons.attach_file,
      required: false,
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.upload_file,
            label: 'Upload Documents',
            onPressed: _pickDocuments,
          ),
          if (_supportingDocuments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_supportingDocuments.length} document(s) selected:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._supportingDocuments.map((file) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.path.split('/').last,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitClaim,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Submit Claim',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool required,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade600,
          side: BorderSide(color: Colors.green.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled. Please enable them.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions are permanently denied.');
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _showSuccessSnackBar('Location captured successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to get location: $e');
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _cropPhoto = photo;
      });
      _showSuccessSnackBar('Photo selected successfully!');
    }
  }

  Future<void> _pickDocuments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _supportingDocuments = result.paths.map((path) => File(path!)).toList();
      });
      _showSuccessSnackBar('${result.files.length} document(s) selected!');
    }
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill all required fields.');
      return;
    }

    if (_cropPhoto == null) {
      _showErrorSnackBar('Please take or select a crop photo.');
      return;
    }

    if (_currentPosition == null) {
      _showErrorSnackBar('Please capture GPS location.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        _showErrorSnackBar('Please login again.');
        return;
      }

      // Upload crop photo
      final String photoUrl = await _firebaseService.uploadFile(
        File(_cropPhoto!.path),
        'crop_photos/${DateTime.now().millisecondsSinceEpoch}_${_cropPhoto!.name}',
      );

      // Upload supporting documents
      final List<String> documentUrls = [];
      for (File doc in _supportingDocuments) {
        final String docUrl = await _firebaseService.uploadFile(
          doc,
          'supporting_documents/${DateTime.now().millisecondsSinceEpoch}_${doc.path.split('/').last}',
        );
        documentUrls.add(docUrl);
      }

      final claim = Claim(
        id: '',
        userId: authState.appUser.id,
        imageUrl: photoUrl,
        documentUrls: documentUrls,
        gps: GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        reason: _selectedDamageType!,
        status: ClaimStatus.pending,
        officerRemarks: '',
        submittedAt: Timestamp.now(),
        landAddress: _landAddressController.text.trim(),
        surveyKhasraNumber: _surveyKhasraNumberController.text.trim(),
        areaInAcres: double.parse(_areaController.text.trim()),
      );

      await _firebaseService.submitClaim(claim);

      _showSuccessSnackBar('Claim submitted successfully!');
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Failed to submit claim: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
