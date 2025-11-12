// models/caregiver_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverProfile {
  final String id;
  final String caregiverId;
  final String firstName;
  final String lastName;
  final String bio;
  final String email;
  final String phone;
  final double hourlyRate;
  final int availableHoursPerWeek;
  final List<String> languages;
  final int experienceYears;
  final String licenseNumber;
  final String education;
  final String employmentHistory;
  final String otherExperience;
  final List<String> skills;
  final List<Certification> certifications;
  final String verificationIdUrl;
  final String? profilePhotoUrl;
  final DateTime createdAt;

  CaregiverProfile({
    required this.id,
    required this.caregiverId,
    required this.firstName,
    required this.lastName,
    required this.bio,
    required this.email,
    required this.phone,
    required this.hourlyRate,
    required this.availableHoursPerWeek,
    required this.languages,
    required this.experienceYears,
    required this.licenseNumber,
    required this.education,
    required this.employmentHistory,
    required this.otherExperience,
    required this.skills,
    required this.certifications,
    required this.verificationIdUrl,
    this.profilePhotoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caregiverId': caregiverId,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'email': email,
      'phone': phone,
      'hourlyRate': hourlyRate,
      'availableHoursPerWeek': availableHoursPerWeek,
      'languages': languages,
      'experienceYears': experienceYears,
      'licenseNumber': licenseNumber,
      'education': education,
      'employmentHistory': employmentHistory,
      'otherExperience': otherExperience,
      'skills': skills,
      'certifications': certifications.map((c) => c.toMap()).toList(),
      'verificationIdUrl': verificationIdUrl,
      'profilePhotoUrl': profilePhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt), // FIXED: Store as Timestamp
    };
  }

  factory CaregiverProfile.fromMap(Map<String, dynamic> map, String id) {
    // Handle createdAt - can be String or Timestamp
    DateTime createdAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is String) {
        createdAt = DateTime.parse(map['createdAt']);
      } else if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    return CaregiverProfile(
      id: id,
      caregiverId: map['caregiverId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      bio: map['bio'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      availableHoursPerWeek: map['availableHoursPerWeek'] ?? 0,
      languages: List<String>.from(map['languages'] ?? []),
      experienceYears: map['experienceYears'] ?? 0,
      licenseNumber: map['licenseNumber'] ?? '',
      education: map['education'] ?? '',
      employmentHistory: map['employmentHistory'] ?? '',
      otherExperience: map['otherExperience'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      certifications: (map['certifications'] as List?)
              ?.map((c) => Certification.fromMap(c))
              .toList() ??
          [],
      verificationIdUrl: map['verificationIdUrl'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'],
      createdAt: createdAt,
    );
  }
}

class Certification {
  final String name;
  final String imageUrl;

  Certification({required this.name, required this.imageUrl});

  Map<String, dynamic> toMap() => {'name': name, 'imageUrl': imageUrl};

  factory Certification.fromMap(Map<String, dynamic> map) {
    return Certification(
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}