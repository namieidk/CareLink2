// lib/models/caregiver_assign.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverAssign {
  final String id;
  final String patientId;
  final String caregiverId;
  final DateTime assignedAt;
  final String status; // 'active', 'removed', 'completed'
  final DateTime? removedAt;
  final String? removedReason;

  CaregiverAssign({
    required this.id,
    required this.patientId,
    required this.caregiverId,
    required this.assignedAt,
    required this.status,
    this.removedAt,
    this.removedReason,
  });

  // From Firestore document
  factory CaregiverAssign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CaregiverAssign(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      removedAt: (data['removedAt'] as Timestamp?)?.toDate(),
      removedReason: data['removedReason'],
    );
  }

  // From Map (for testing or local use)
  factory CaregiverAssign.fromMap(Map<String, dynamic> data, String id) {
    return CaregiverAssign(
      id: id,
      patientId: data['patientId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      removedAt: (data['removedAt'] as Timestamp?)?.toDate(),
      removedReason: data['removedReason'],
    );
  }

  // Convert to Map for Firestore update
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

  // For creating new assignment
  Map<String, dynamic> toMapForCreation() {
    return {
      'patientId': patientId,
      'caregiverId': caregiverId,
      'assignedAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'removedAt': null,
      'removedReason': null,
    };
  }

  // Copy with updates
  CaregiverAssign copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    DateTime? assignedAt,
    String? status,
    DateTime? removedAt,
    String? removedReason,
  }) {
    return CaregiverAssign(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      assignedAt: assignedAt ?? this.assignedAt,
      status: status ?? this.status,
      removedAt: removedAt ?? this.removedAt,
      removedReason: removedReason ?? this.removedReason,
    );
  }

  // Convenience getters
  bool get isActive => status == 'active';
  bool get isRemoved => status == 'removed';
  bool get isCompleted => status == 'completed';

  @override
  String toString() {
    return 'CaregiverAssign(id: $id, patientId: $patientId, caregiverId: $caregiverId, status: $status)';
  }
}