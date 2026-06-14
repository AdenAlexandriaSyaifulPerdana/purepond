import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String parameter;
  final double value;
  final double threshold;
  final bool isRead;
  final Timestamp createdAt;

  NotificationModel({
    this.id = '',
    required this.title,
    required this.body,
    required this.type,
    required this.parameter,
    required this.value,
    required this.threshold,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return NotificationModel(
      id: id,
      title: data['judul'] ?? data['title'] ?? '',
      body: data['isi'] ?? data['body'] ?? '',
      type: data['type'] ?? 'warning',
      parameter: data['parameter'] ?? '',
      value: _toDouble(data['nilai'] ?? data['value']),
      threshold: _toDouble(data['threshold']),
      isRead: data['isRead'] ?? data['is_read'] ?? false,
      createdAt: data['createdAt'] ?? data['created_at'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'judul': title,
      'isi': body,
      'type': type,
      'parameter': parameter,
      'nilai': value,
      'threshold': threshold,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  DateTime get dateTime => createdAt.toDate();

  bool get isDrainNotification => type == 'drain';
  bool get isWarningNotification => type == 'warning';

  static double _toDouble(dynamic value, [double defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
