import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

enum ClaimStatus {
  pending,
  approved,
  rejected,
}

class Claim {
  final String id;
  final String userId;
  final String imageUrl;
  final List<String> documentUrls;
  final GeoPoint gps;
  final String reason;
  final ClaimStatus status;
  final String officerRemarks;
  final Timestamp submittedAt;
  final String landAddress;
  final String surveyKhasraNumber;
  final double areaInAcres;

  Claim({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.documentUrls,
    required this.gps,
    required this.reason,
    required this.status,
    required this.officerRemarks,
    required this.submittedAt,
    required this.landAddress,
    required this.surveyKhasraNumber,
    required this.areaInAcres,
  });

  factory Claim.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Claim(
      id: doc.id,
      userId: data['user_id'] ?? '',
      imageUrl: data['image_url'] ?? '',
      documentUrls: List<String>.from(data['document_urls'] ?? []),
      gps: data['gps'] ?? const GeoPoint(0, 0),
      reason: data['reason'] ?? '',
      status: ClaimStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => ClaimStatus.pending,
      ),
      officerRemarks: data['officer_remarks'] ?? '',
      submittedAt: data['submitted_at'] ?? Timestamp.now(),
      landAddress: data['land_address'] ?? '',
      surveyKhasraNumber: data['survey_khasra_number'] ?? '',
      areaInAcres: (data['area_in_acres'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'image_url': imageUrl,
      'document_urls': documentUrls,
      'gps': gps,
      'reason': reason,
      'status': status.toString().split('.').last,
      'officer_remarks': officerRemarks,
      'submitted_at': submittedAt,
      'land_address': landAddress,
      'survey_khasra_number': surveyKhasraNumber,
      'area_in_acres': areaInAcres,
    };
  }
}
