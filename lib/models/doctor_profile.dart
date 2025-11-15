import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfile {
  final String id; // Document ID (usually user ID)
  final String name;
  final String specialty;
  final String hospital;
  final String email;
  final String phone;
  final String address;
  final String experience;
  final String education;
  final String languages;
  final String bio;
  final String? profileImageUrl;
  final DateTime joinedDate;
  final String licenseNumber;
  final int yearsOfExperience;
  final int patientsTreated;
  final double patientSatisfaction;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.email,
    required this.phone,
    required this.address,
    required this.experience,
    required this.education,
    required this.languages,
    required this.bio,
    this.profileImageUrl,
    required this.joinedDate,
    required this.licenseNumber,
    this.yearsOfExperience = 0,
    this.patientsTreated = 0,
    this.patientSatisfaction = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create DoctorProfile from Firestore document
  factory DoctorProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return DoctorProfile(
      id: doc.id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      hospital: data['hospital'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      experience: data['experience'] ?? '',
      education: data['education'] ?? '',
      languages: data['languages'] ?? '',
      bio: data['bio'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      joinedDate: (data['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      licenseNumber: data['licenseNumber'] ?? '',
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      patientsTreated: data['patientsTreated'] ?? 0,
      patientSatisfaction: (data['patientSatisfaction'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Factory constructor to create DoctorProfile from Map
  factory DoctorProfile.fromMap(Map<String, dynamic> data, String documentId) {
    return DoctorProfile(
      id: documentId,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      hospital: data['hospital'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      experience: data['experience'] ?? '',
      education: data['education'] ?? '',
      languages: data['languages'] ?? '',
      bio: data['bio'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      joinedDate: (data['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      licenseNumber: data['licenseNumber'] ?? '',
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      patientsTreated: data['patientsTreated'] ?? 0,
      patientSatisfaction: (data['patientSatisfaction'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert DoctorProfile to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'hospital': hospital,
      'email': email,
      'phone': phone,
      'address': address,
      'experience': experience,
      'education': education,
      'languages': languages,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'licenseNumber': licenseNumber,
      'yearsOfExperience': yearsOfExperience,
      'patientsTreated': patientsTreated,
      'patientSatisfaction': patientSatisfaction,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method for updating specific fields
  DoctorProfile copyWith({
    String? id,
    String? name,
    String? specialty,
    String? hospital,
    String? email,
    String? phone,
    String? address,
    String? experience,
    String? education,
    String? languages,
    String? bio,
    String? profileImageUrl,
    DateTime? joinedDate,
    String? licenseNumber,
    int? yearsOfExperience,
    int? patientsTreated,
    double? patientSatisfaction,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      hospital: hospital ?? this.hospital,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      languages: languages ?? this.languages,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      patientsTreated: patientsTreated ?? this.patientsTreated,
      patientSatisfaction: patientSatisfaction ?? this.patientSatisfaction,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get initials from name
  String getInitials() {
    final parts = name.split(' ');
    if (parts.length < 2) return name.substring(0, 2).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // Check if profile is complete (has essential fields)
  bool get isComplete {
    return name.isNotEmpty &&
        specialty.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty;
  }

  // Get display name (Dr. + Last Name)
  String get displayName {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return 'Dr. ${parts.last}';
    }
    return name;
  }

  // Get years of experience as formatted string
  String get experienceFormatted {
    if (yearsOfExperience == 0) return 'New';
    if (yearsOfExperience == 1) return '1 year';
    return '$yearsOfExperience years';
  }

  // Get satisfaction as percentage string
  String get satisfactionPercentage {
    return '${patientSatisfaction.toStringAsFixed(1)}%';
  }

  @override
  String toString() {
    return 'DoctorProfile(id: $id, name: $name, specialty: $specialty, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DoctorProfile &&
        other.id == id &&
        other.name == name &&
        other.specialty == specialty &&
        other.hospital == hospital &&
        other.email == email &&
        other.phone == phone;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      specialty,
      hospital,
      email,
      phone,
    );
  }
}