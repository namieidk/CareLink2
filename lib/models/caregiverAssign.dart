// lib/models/caregiver_assignment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverAssignment {
  final String id;
  final String patientId;
  final String caregiverId;
  final DateTime assignedAt;
  final String status; // 'active', 'removed', 'completed'
  final DateTime? removedAt;
  final String? removedReason;

  CaregiverAssignment({
    required this.id,
    required this.patientId,
    required this.caregiverId,
    required this.assignedAt,
    required this.status,
    this.removedAt,
    this.removedReason,
  });

  // Create from Firestore document
  factory CaregiverAssignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CaregiverAssignment(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      removedAt: (data['removedAt'] as Timestamp?)?.toDate(),
      removedReason: data['removedReason'],
    );
  }

  // Create from Map
  factory CaregiverAssignment.fromMap(Map<String, dynamic> data, String id) {
    return CaregiverAssignment(
      id: id,
      patientId: data['patientId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      removedAt: (data['removedAt'] as Timestamp?)?.toDate(),
      removedReason: data['removedReason'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'caregiverId': caregiverId,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'status': status,
      'removedAt': removedAt != null ? Timestamp.fromDate(removedAt!) : null,
      'removedReason': removedReason,
    };
  }

  // Convert to Map for creation (uses FieldValue.serverTimestamp)
  Map<String, dynamic> toMapForCreation() {
    return {
      'patientId': patientId,
      'caregiverId': caregiverId,
      'assignedAt': FieldValue.serverTimestamp(),
      'status': status,
      'removedAt': null,
      'removedReason': null,
    };
  }

  // Copy with method for updates
  CaregiverAssignment copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    DateTime? assignedAt,
    String? status,
    DateTime? removedAt,
    String? removedReason,
  }) {
    return CaregiverAssignment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      assignedAt: assignedAt ?? this.assignedAt,
      status: status ?? this.status,
      removedAt: removedAt ?? this.removedAt,
      removedReason: removedReason ?? this.removedReason,
    );
  }

  // Check if assignment is active
  bool get isActive => status == 'active';

  // Check if assignment is removed
  bool get isRemoved => status == 'removed';

  // Check if assignment is completed
  bool get isCompleted => status == 'completed';
}

