import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String parameter;
  final double value;
  final bool isRead;
  final Timestamp createdAt;

  NotificationModel({
    this.id = '',
    required this.title,
    required this.body,
    required this.parameter,
    required this.value,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(
      String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      title: data['judul'] ?? data['title'] ?? '', // Support both
      body: data['isi'] ?? data['body'] ?? '', // Support both
      parameter: data['parameter'] ?? '',
      value: (data['nilai'] ?? data['value'] ?? 0).toDouble(), // Support both
      isRead: data['isRead'] ?? data['is_read'] ?? false, // Support both
      createdAt: data['createdAt'] ?? data['created_at'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'judul': title,
      'isi': body,
      'parameter': parameter,
      'nilai': value,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  DateTime get dateTime => createdAt.toDate();
}
