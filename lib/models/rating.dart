// lib/models/rating_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;

  final String fromUserId;
  final String fromUserRole;   // "patient" or "caregiver"
  final String fromUserName;
  final String? fromUserPhotoUrl;

  final String toUserId;
  final String toUserRole;     // opposite of fromUserRole
  final String toUserName;
  final String? toUserPhotoUrl;

  final String jobId;

  final double rating;
  final double? punctuality;
  final double? communication;
  final double? professionalism;
  final double? overallCare;

  final String comment;
  final bool isAnonymous;

  final Timestamp createdAt;
  final Timestamp? updatedAt;

  RatingModel({
    required this.id,
    required this.fromUserId,
    required this.fromUserRole,
    required this.fromUserName,
    this.fromUserPhotoUrl,
    required this.toUserId,
    required this.toUserRole,
    required this.toUserName,
    this.toUserPhotoUrl,
    required this.jobId,
    required this.rating,
    this.punctuality,
    this.communication,
    this.professionalism,
    this.overallCare,
    required this.comment,
    this.isAnonymous = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map, String docId) {
    return RatingModel(
      id: docId,
      fromUserId: map['fromUserId'] as String,
      fromUserRole: map['fromUserRole'] as String,
      fromUserName: map['fromUserName'] as String,
      fromUserPhotoUrl: map['fromUserPhotoUrl'] as String?,
      toUserId: map['toUserId'] as String,
      toUserRole: map['toUserRole'] as String,
      toUserName: map['toUserName'] as String,
      toUserPhotoUrl: map['toUserPhotoUrl'] as String?,
      jobId: map['jobId'] as String,
      rating: (map['rating'] as num).toDouble(),
      punctuality: map['punctuality'] != null ? (map['punctuality'] as num).toDouble() : null,
      communication: map['communication'] != null ? (map['communication'] as num).toDouble() : null,
      professionalism: map['professionalism'] != null ? (map['professionalism'] as num).toDouble() : null,
      overallCare: map['overallCare'] != null ? (map['overallCare'] as num).toDouble() : null,
      comment: map['comment'] as String? ?? '',
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      createdAt: map['createdAt'] as Timestamp,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUserRole': fromUserRole,
      'fromUserName': fromUserName,
      if (fromUserPhotoUrl != null) 'fromUserPhotoUrl': fromUserPhotoUrl,
      'toUserId': toUserId,
      'toUserRole': toUserRole,
      'toUserName': toUserName,
      if (toUserPhotoUrl != null) 'toUserPhotoUrl': toUserPhotoUrl,
      'jobId': jobId,
      'rating': rating,
      if (punctuality != null) 'punctuality': punctuality,
      if (communication != null) 'communication': communication,
      if (professionalism != null) 'professionalism': professionalism,
      if (overallCare != null) 'overallCare': overallCare,
      'comment': comment,
      'isAnonymous': isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}