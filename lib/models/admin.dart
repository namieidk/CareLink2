import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class Admin extends User {
  final String username;
  final String email;

  Admin({
    required String id,
    required String username,
    required String email,
    required String password,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool isActive = true,
    String? profilePicture,
    String? fullName,
    DateTime? lastLogin,
  }) : username = username,
       email = email,
       super(
         id: id,
         password: password,
         createdAt: createdAt ?? DateTime.now(),
         updatedAt: updatedAt,
         isActive: isActive,
         profilePicture: profilePicture,
         fullName: fullName,
         lastLogin: lastLogin,
       );

  // Firestore collection
  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('admins');

  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'username': username,
      'email': email,
    });
    return map;
  }

  static Admin fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'],
      username: map['username'],
      email: map['email'],
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
