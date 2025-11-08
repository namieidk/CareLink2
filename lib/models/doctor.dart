import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class Doctor extends User {
  final String doctorId;
  final String username;

  Doctor({
    required String id,
    required this.doctorId,
    required this.username,
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
      FirebaseFirestore.instance.collection('doctors');

  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'doctorId': doctorId,
      'username': username,
    });
    return map;
  }

  static Doctor fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      doctorId: map['doctorId'],
      username: map['username'],
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
