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

class ClaimFormScreen extends StatefulWidget {
  const ClaimFormScreen({super.key});

  @override
  State<ClaimFormScreen> createState() => _ClaimFormScreenState();
}

class _ClaimFormScreenState extends State<ClaimFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _landAddressController = TextEditingController();
  final TextEditingController _surveyKhasraNumberController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  String? _selectedDamageType;
  XFile? _cropPhoto;
  List<File> _supportingDocuments = [];
  Position? _currentPosition;
  bool _isLoading = false;

  final List<String> _damageTypes = [
    'Drought',
    'Pest',
    'Flood',
    'Hailstorm',
    'Other'
  ];

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('location_services_disabled'.tr())),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('location_permission_denied'.tr())),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('location_permission_denied_forever'.tr())),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('location_fetched_success'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'location_fetch_error'.tr()}: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: source);
    setState(() {
      _cropPhoto = photo;
    });
  }

  Future<void> _pickDocuments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _supportingDocuments =
            result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  Future<void> _submitClaim() async {
    if (_formKey.currentState!.validate()) {
      if (_cropPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('crop_photo_required'.tr())),
        );
        return;
      }
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('gps_location_required'.tr())),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final authState = context.read<AuthBloc>().state;
        String? userId;
        if (authState is AuthAuthenticated) {
          userId = authState.appUser.id;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('user_not_authenticated'.tr())),
          );
          setState(() {
            _isLoading = false;
          });
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
          id: '', // Firestore will generate this
          userId: userId!,
          imageUrl: photoUrl,
          documentUrls: documentUrls,
          gps: GeoPoint(
              _currentPosition!.latitude, _currentPosition!.longitude),
          reason: _selectedDamageType!,
          status: ClaimStatus.pending,
          officerRemarks: '',
          submittedAt: Timestamp.now(),
          landAddress: _landAddressController.text,
          surveyKhasraNumber: _surveyKhasraNumberController.text,
          areaInAcres: double.parse(_areaController.text),
        );

        await _firebaseService.submitClaim(claim);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('claim_submitted_success'.tr())),
        );
        _formKey.currentState!.reset();
        setState(() {
          _cropPhoto = null;
          _supportingDocuments = [];
          _selectedDamageType = null;
          _landAddressController.clear();
          _surveyKhasraNumberController.clear();
          _areaController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'claim_submission_error'.tr()}: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('claim_submission_title'.tr())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('crop_photo_label'.tr(),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _cropPhoto == null
                        ? ElevatedButton(
                            onPressed: () => _pickImage(ImageSource.camera),
                            child: Text('take_photo_button'.tr()),
                          )
                        : Image.file(File(_cropPhoto!.path), height: 150),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      child: Text('select_from_gallery_button'.tr()),
                    ),
                    const SizedBox(height: 24),
                    Text('type_of_damage_label'.tr(),
                        style: Theme.of(context).textTheme.titleMedium),
                    DropdownButtonFormField<String>(
                      value: _selectedDamageType,
                      hint: Text('select_damage_type_hint'.tr()),
                      items: _damageTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type.tr()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDamageType = newValue;
                        });
                      },
                      validator: (value) => value == null
                          ? 'please_select_damage_type'.tr()
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text('gps_location_label'.tr(),
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      _currentPosition == null
                          ? 'fetching_location'.tr()
                          : '${'latitude'.tr()}: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${'longitude'.tr()}: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    ),
                    ElevatedButton(
                      onPressed: _getCurrentLocation,
                      child: Text('refresh_location_button'.tr()),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _landAddressController,
                      decoration: InputDecoration(
                        labelText: 'land_address_label'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'please_enter_land_address'.tr()
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _surveyKhasraNumberController,
                      decoration: InputDecoration(
                        labelText: 'survey_khasra_number_label'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'please_enter_survey_khasra_number'.tr()
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _areaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'area_in_acres_label'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'please_enter_area'.tr();
                        }
                        if (double.tryParse(value) == null) {
                          return 'please_enter_valid_number'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text('supporting_documents_label'.tr(),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _pickDocuments,
                      child: Text('upload_documents_button'.tr()),
                    ),
                    if (_supportingDocuments.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _supportingDocuments
                            .map((file) => Text(file.path.split('/').last))
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitClaim,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                        child: Text('submit_claim_button'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
