// lib/models/booking.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String patientId;
  final String patientName;
  final String caregiverId;
  final String caregiverName;
  final String interviewType; // "Video Call" or "In-Person"
  final Timestamp startTime;
  final int durationHours;
  final double totalCost; // Always 0.0
  final String? notes;
  final String? address; // Only for In-Person
  final String status; // "pending", "accepted", "rejected"
  final Timestamp createdAt;

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
    this.status = 'pending',
    required this.createdAt,
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
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
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
      'status': status,
      'createdAt': createdAt,
    };
  }
}