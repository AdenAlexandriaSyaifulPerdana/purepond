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
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      parameter: data['parameter'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'parameter': parameter,
      'value': value,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  DateTime get dateTime => createdAt.toDate();
}
