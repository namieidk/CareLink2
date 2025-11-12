// lib/models/patient_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      relation: map['relation'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relation': relation,
      'phone': phone,
    };
  }
}

class PatientProfile {
  final String id;
  final String patientId;
  final String fullName;
  final int age;
  final String email;
  final String phone;
  final String address;
  final String bloodType;
  final List<String> allergies;
  final List<String> conditions;
  final List<EmergencyContact> emergencyContacts;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PatientProfile({
    required this.id,
    required this.patientId,
    required this.fullName,
    required this.age,
    required this.email,
    required this.phone,
    required this.address,
    required this.bloodType,
    required this.allergies,
    required this.conditions,
    required this.emergencyContacts,
    this.profilePhotoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory PatientProfile.fromMap(Map<String, dynamic> map, String docId) {
    return PatientProfile(
      id: docId,
      patientId: map['patientId'] ?? '',
      fullName: map['fullName'] ?? '',
      age: map['age'] ?? 0,
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      bloodType: map['bloodType'] ?? '',
      allergies: List<String>.from(map['allergies'] ?? []),
      conditions: List<String>.from(map['conditions'] ?? []),
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      profilePhotoUrl: map['profilePhotoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'fullName': fullName,
      'age': age,
      'email': email,
      'phone': phone,
      'address': address,
      'bloodType': bloodType,
      'allergies': allergies,
      'conditions': conditions,
      'emergencyContacts': emergencyContacts.map((c) => c.toMap()).toList(),
      'profilePhotoUrl': profilePhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }
}