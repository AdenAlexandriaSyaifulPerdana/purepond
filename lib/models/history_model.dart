import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryModel {
  final String id;
  final String type;
  final String trigger;
  final double turbidity;
  final double ammonia;
  final double ph;
  final int duration;
  final Timestamp timestamp;

  HistoryModel({
    this.id = '',
    required this.type,
    required this.trigger,
    required this.turbidity,
    required this.ammonia,
    required this.ph,
    required this.duration,
    required this.timestamp,
  });

  factory HistoryModel.fromFirestore(String id, Map<String, dynamic> data) {
    return HistoryModel(
      id: id,
      type: data['type'] ?? 'Manual',
      trigger: data['trigger'] ?? 'Manual',
      turbidity: (data['turbidity'] ?? 0).toDouble(),
      ammonia: (data['ammonia'] ?? 0).toDouble(),
      ph: (data['ph'] ?? 7).toDouble(),
      duration: data['duration'] ?? 0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'trigger': trigger,
      'turbidity': turbidity,
      'ammonia': ammonia,
      'ph': ph,
      'duration': duration,
      'timestamp': timestamp,
    };
  }
}
