import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfile {
  final String adminId;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? location;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminProfile({
    required this.adminId,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.location,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  // Firestore collection
  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('admin_profiles');

  /// Convert AdminProfile to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'location': location,
      'bio': bio,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create AdminProfile from Firestore Map
  static AdminProfile fromMap(Map<String, dynamic> map) {
    return AdminProfile(
      adminId: map['adminId'],
      fullName: map['fullName'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      location: map['location'],
      bio: map['bio'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']))
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
    );
  }

  /// Create AdminProfile from Firestore DocumentSnapshot
  static AdminProfile fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    data['adminId'] = snapshot.id;
    return fromMap(data);
  }

  /// Copy with method for creating modified instances
  AdminProfile copyWith({
    String? adminId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? location,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminProfile(
      adminId: adminId ?? this.adminId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}