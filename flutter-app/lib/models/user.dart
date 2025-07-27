import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String phone;
  final String aadhar;
  final String address;
  final Timestamp createdAt;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.aadhar,
    required this.address,
    required this.createdAt,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      aadhar: data['aadhar'] ?? '',
      address: data['address'] ?? '',
      createdAt: data['created_at'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'aadhar': aadhar,
      'address': address,
      'created_at': createdAt,
    };
  }
}
