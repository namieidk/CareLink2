// lib/models/booking.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String patientId;
  final String patientName;
  final String caregiverId;
  final String caregiverName;
  final String interviewType;
  final Timestamp startTime;
  final int durationHours;
  final double totalCost;
  final String? notes;
  final String? address;
  final String? meetLink;          // ← added
  final String status;             // "pending", "accepted", "rejected"
  final String? requestedBy;       // ← NEW: 'patient' or 'caregiver'
  final Timestamp createdAt;
  final Timestamp? respondedAt;    // ← added (when caregiver/patient responds)

  BookingModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.caregiverId,
    required this.caregiverName,
    required this.interviewType,
    required this.startTime,
    required this.durationHours,
    this.totalCost = 0.0,
    this.notes,
    this.address,
    this.meetLink,
    this.status = 'pending',
    this.requestedBy,
    required this.createdAt,
    this.respondedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      caregiverId: map['caregiverId'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      interviewType: map['interviewType'] ?? '',
      startTime: map['startTime'] ?? Timestamp.now(),
      durationHours: map['durationHours'] ?? 1,
      totalCost: (map['totalCost'] ?? 0.0).toDouble(),
      notes: map['notes'],
      address: map['address'],
      meetLink: map['meetLink'],
      status: map['status'] ?? 'pending',
      requestedBy: map['requestedBy'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      respondedAt: map['respondedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'interviewType': interviewType,
      'startTime': startTime,
      'durationHours': durationHours,
      'totalCost': totalCost,
      'notes': notes,
      'address': address,
      'meetLink': meetLink,
      'status': status,
      'requestedBy': requestedBy,
      'createdAt': createdAt,
      if (respondedAt != null) 'respondedAt': respondedAt,
    };
  }
}