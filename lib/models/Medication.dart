// lib/models/medication.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String patientId;
  final String name;
  final String dose;
  final List<String> times; // Multiple times support
  final String period;      // e.g., "Morning", "Afternoon", "Evening", "Night"
  final String frequency;   // e.g., "Daily", "Every 2 days", "Weekly"
  final String purpose;
  final String instructions;
  final String sideEffects;
  final String prescribedBy;
  final String prescribedById;
  final String doctorSpecialty;
  final String doctorHospital;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Medication({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dose,
    required this.times,
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
    this.updatedAt,
  });

  // Returns first time for backward compatibility
  String get time => times.isNotEmpty ? times.first : 'As needed';

  // Returns formatted time string for display
  String get timeDisplay {
    if (times.isEmpty) return 'As needed';
    if (times.length == 1) return times.first;
    if (times.length == 2) return '${times.first} & ${times.last}';
    return '${times.first} & ${times.length - 1} more';
  }

  // Factory constructor from Firestore
  factory Medication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime? parseTimestamp(String field) {
      try {
        final value = data[field];
        if (value == null) return null;
        if (value is Timestamp) return value.toDate();
        if (value is String) return DateTime.tryParse(value);
        return null;
      } catch (e) {
        print('Error parsing $field: $e');
        return null;
      }
    }

    // Safely parse 'times' as List<String>
    List<String> parseTimes() {
      final timesData = data['times'];
      if (timesData is List) {
        return timesData.map((t) => t.toString()).toList();
      }
      // Fallback: if old data uses 'time' (single string)
      final oldTime = data['time'] as String?;
      return oldTime != null && oldTime.isNotEmpty ? [oldTime] : [];
    }

    return Medication(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      name: data['name'] ?? '',
      dose: data['dose'] ?? '',
      times: parseTimes(),
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
      createdAt: parseTimestamp('createdAt'),
      updatedAt: parseTimestamp('updatedAt'),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'name': name,
      'dose': dose,
      'times': times,
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
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // For updates (exclude createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'dose': dose,
      'times': times,
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
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // CopyWith
  Medication copyWith({
    String? id,
    String? patientId,
    String? name,
    String? dose,
    List<String>? times,
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
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      times: times ?? this.times,
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
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper: Check if any dose is pending today
  bool hasPendingDoseToday() {
    final now = DateTime.now();
    final todayStr = _formatTime(now);

    return times.any((time) {
      final medTime = _parseTime(time);
      if (medTime == null) return false;
      final medDateTime = DateTime(now.year, now.month, now.day, medTime.hour, medTime.minute);
      return medDateTime.isAfter(now);
    });
  }

  // Helper: Format time string to HH:mm
  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // Helper: Parse "08:00 AM" → DateTime (time only)
  DateTime? _parseTime(String timeStr) {
    try {
      final format = RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)', caseSensitive: false);
      final match = format.firstMatch(timeStr);
      if (match == null) return null;

      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return DateTime(2020, 1, 1, hour, minute); // Dummy date
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dose: $dose, times: $times, period: $period, frequency: $frequency)';
  }
}