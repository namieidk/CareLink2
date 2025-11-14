// lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.timestamp,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  static Message fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      text: map['text'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      receiverName: map['receiverName'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}