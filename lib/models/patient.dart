import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class Patient extends User {
  final String email;
  final String phone;

  Patient({
    required String id,
    required this.email,
    required this.phone,
    required String password,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool isActive = true,
    String? profilePicture,
    String? fullName,
    DateTime? lastLogin,
  }) : super(
          id: id,
          password: password,
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt,
          isActive: isActive,
          profilePicture: profilePicture,
          fullName: fullName,
          lastLogin: lastLogin,
        );

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('patients');

  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'email': email,
      'phone': phone,
    });
    return map;
  }

  static Patient fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      email: map['email'],
      phone: map['phone'],
      password: map['password'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isActive: map['isActive'] ?? true,
      profilePicture: map['profilePicture'],
      fullName: map['fullName'],
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
    );
  }
}
