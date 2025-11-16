import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationHistory {
  final String id;
  final String patientId;
  final String medicationId;
  final String medicationName;
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
  final String status; // 'taken' or 'missed'
  final DateTime takenAt;
  final DateTime? scheduledTime;

  MedicationHistory({
    required this.id,
    required this.patientId,
    required this.medicationId,
    required this.medicationName,
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
    required this.status,
    required this.takenAt,
    this.scheduledTime,
  });

  // Safe datetime parsing helper
  static DateTime? _parseDateTime(dynamic value) {
    try {
      if (value == null) return null;
      
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      } else if (value is DateTime) {
        return value;
      }
      return null;
    } catch (e) {
      print('Error parsing datetime: $e');
      return null;
    }
  }

  // Factory constructor to create MedicationHistory from Firestore document
  factory MedicationHistory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return MedicationHistory(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
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
      status: data['status'] ?? 'taken',
      takenAt: _parseDateTime(data['takenAt']) ?? DateTime.now(),
      scheduledTime: _parseDateTime(data['scheduledTime']),
    );
  }

  // Convert MedicationHistory to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'medicationId': medicationId,
      'medicationName': medicationName,
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
      'status': status,
      'takenAt': Timestamp.fromDate(takenAt),
      'scheduledTime': scheduledTime != null 
          ? Timestamp.fromDate(scheduledTime!) 
          : null,
    };
  }

  // Format the taken date/time
  String get formattedTakenAt {
    final now = DateTime.now();
    final difference = now.difference(takenAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(takenAt)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago, ${_formatTime(takenAt)}';
    } else {
      return '${takenAt.day}/${takenAt.month}/${takenAt.year}, ${_formatTime(takenAt)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  String toString() {
    return 'MedicationHistory(id: $id, medicationName: $medicationName, status: $status, takenAt: $takenAt)';
  }
}