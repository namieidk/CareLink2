import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class Doctor extends User {
  final String doctorId;
  final String username;
  final String email;

  Doctor({
    required String id,
    required this.doctorId,
    required this.username,
    required this.email,
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

  /// Convert Doctor object to Map for Firestore
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'doctorId': doctorId,
      'username': username,
      'email': email,
    });
    return map;
  }

  /// Create Doctor object from Firestore Map
  static Doctor fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      doctorId: map['doctorId'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt']))
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['updatedAt']))
          : null,
      isActive: map['isActive'] ?? true,
      profilePicture: map['profilePicture'],
      fullName: map['fullName'],
      lastLogin: map['lastLogin'] != null 
          ? (map['lastLogin'] is Timestamp 
              ? (map['lastLogin'] as Timestamp).toDate() 
              : DateTime.parse(map['lastLogin']))
          : null,
    );
  }

  /// Create Doctor object from Firestore DocumentSnapshot
  static Doctor fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    data['id'] = snapshot.id;
    return fromMap(data);
  }

  /// Copy with method for creating modified instances
  Doctor copyWith({
    String? id,
    String? doctorId,
    String? username,
    String? email,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? profilePicture,
    String? fullName,
    DateTime? lastLogin,
  }) {
    return Doctor(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      profilePicture: profilePicture ?? this.profilePicture,
      fullName: fullName ?? this.fullName,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}