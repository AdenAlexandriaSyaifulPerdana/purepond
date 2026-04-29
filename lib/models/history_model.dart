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
    // Baca field dengan beberapa kemungkinan nama
    String type = data['tipe'] ?? data['type'] ?? 'Otomatis';
    String trigger = data['pemicu'] ?? data['trigger'] ?? 'Kekeruhan';
    double turbidity = (data['turbidity'] ?? 0).toDouble();
    double ammonia = (data['ammonia'] ?? 0).toDouble();
    double ph = (data['ph'] ?? 7).toDouble();

    // Konversi durasi dengan aman (bisa int atau double)
    int duration;
    var durationRaw = data['durasi'] ?? data['duration'] ?? 0;
    if (durationRaw is double) {
      duration = durationRaw.toInt();
    } else {
      duration = durationRaw as int;
    }

    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();

    return HistoryModel(
      id: id,
      type: type,
      trigger: trigger,
      turbidity: turbidity,
      ammonia: ammonia,
      ph: ph,
      duration: duration,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipe': type,
      'pemicu': trigger,
      'turbidity': turbidity,
      'ammonia': ammonia,
      'ph': ph,
      'durasi': duration,
      'timestamp': timestamp,
    };
  }
}
