import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String patientId;
  final String name;
  final String dose;
  final String time;
  final String period;
  final String frequency;
  final String purpose;
  final String instructions;
  final String sideEffects;
  final String prescribedBy;
  final String prescribedById;
  final String doctorSpecialty;
  final String doctorHospital;
  final bool isActive;
  final DateTime? createdAt;

  Medication({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dose,
    required this.time,
    required this.period,
    required this.frequency,
    required this.purpose,
    required this.instructions,
    required this.sideEffects,
    required this.prescribedBy,
    required this.prescribedById,
    required this.doctorSpecialty,
    required this.doctorHospital,
    this.isActive = true,
    this.createdAt,
  });

  // Factory constructor to create Medication from Firestore document
  factory Medication.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Safe timestamp conversion
    DateTime? parseCreatedAt() {
      try {
        final createdAtData = data['createdAt'];
        if (createdAtData == null) return null;
        
        if (createdAtData is Timestamp) {
          return createdAtData.toDate();
        } else if (createdAtData is String) {
          return DateTime.tryParse(createdAtData);
        } else if (createdAtData is DateTime) {
          return createdAtData;
        }
        return null;
      } catch (e) {
        print('Error parsing createdAt: $e');
        return null;
      }
    }
    
    return Medication(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      name: data['name'] ?? '',
      dose: data['dose'] ?? '',
      time: data['time'] ?? '',
      period: data['period'] ?? '',
      frequency: data['frequency'] ?? '',
      purpose: data['purpose'] ?? '',
      instructions: data['instructions'] ?? '',
      sideEffects: data['sideEffects'] ?? '',
      prescribedBy: data['prescribedBy'] ?? '',
      prescribedById: data['prescribedById'] ?? '',
      doctorSpecialty: data['doctorSpecialty'] ?? '',
      doctorHospital: data['doctorHospital'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: parseCreatedAt(),
    );
  }

  // Convert Medication to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'name': name,
      'dose': dose,
      'time': time,
      'period': period,
      'frequency': frequency,
      'purpose': purpose,
      'instructions': instructions,
      'sideEffects': sideEffects,
      'prescribedBy': prescribedBy,
      'prescribedById': prescribedById,
      'doctorSpecialty': doctorSpecialty,
      'doctorHospital': doctorHospital,
      'isActive': isActive,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // CopyWith method for creating modified copies
  Medication copyWith({
    String? id,
    String? patientId,
    String? name,
    String? dose,
    String? time,
    String? period,
    String? frequency,
    String? purpose,
    String? instructions,
    String? sideEffects,
    String? prescribedBy,
    String? prescribedById,
    String? doctorSpecialty,
    String? doctorHospital,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      time: time ?? this.time,
      period: period ?? this.period,
      frequency: frequency ?? this.frequency,
      purpose: purpose ?? this.purpose,
      instructions: instructions ?? this.instructions,
      sideEffects: sideEffects ?? this.sideEffects,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      prescribedById: prescribedById ?? this.prescribedById,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      doctorHospital: doctorHospital ?? this.doctorHospital,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dose: $dose, time: $time, period: $period, prescribedBy: $prescribedBy)';
  }
}