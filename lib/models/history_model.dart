import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryModel {
  final String id;
  final String type;
  final String trigger;
  final double turbidity;
  final double ammonia;

  final int turbidityRaw;
  final int ammoniaRaw;

  final double turbidityVoltage;
  final double ammoniaVoltage;

  final double waterLevelLowerPercent;
  final int waterLevelLowerRaw;
  final double waterLevelLowerVoltage;
  final bool waterLevelLowerEmpty;

  final double waterLevelUpperDistanceCm;
  final bool waterLevelUpperFull;

  final bool isDraining;
  final bool isFilling;
  final bool autoMode;
  final String state;

  final int duration;
  final Timestamp timestamp;

  HistoryModel({
    this.id = '',
    required this.type,
    required this.trigger,
    required this.turbidity,
    required this.ammonia,
    required this.turbidityRaw,
    required this.ammoniaRaw,
    required this.turbidityVoltage,
    required this.ammoniaVoltage,
    required this.waterLevelLowerPercent,
    required this.waterLevelLowerRaw,
    required this.waterLevelLowerVoltage,
    required this.waterLevelLowerEmpty,
    required this.waterLevelUpperDistanceCm,
    required this.waterLevelUpperFull,
    required this.isDraining,
    required this.isFilling,
    required this.autoMode,
    required this.state,
    required this.duration,
    required this.timestamp,
  });

  factory HistoryModel.fromFirestore(String id, Map<String, dynamic> data) {
    final lowerMap = _toMap(data['waterLevelLower']);
    final upperMap = _toMap(data['waterLevelUpper']);

    return HistoryModel(
      id: id,
      type: data['tipe'] ?? data['type'] ?? 'Otomatis',
      trigger: data['pemicu'] ?? data['trigger'] ?? '-',
      turbidity: _toDouble(data['turbidity']),
      ammonia: _toDouble(data['ammonia']),
      turbidityRaw: _toInt(data['turbidityRaw']),
      ammoniaRaw: _toInt(data['ammoniaRaw']),
      turbidityVoltage: _toDouble(data['turbidityVoltage']),
      ammoniaVoltage: _toDouble(data['ammoniaVoltage']),
      waterLevelLowerPercent: _toDouble(lowerMap['percent']),
      waterLevelLowerRaw: _toInt(lowerMap['raw']),
      waterLevelLowerVoltage: _toDouble(lowerMap['voltage']),
      waterLevelLowerEmpty: lowerMap['empty'] == true,
      waterLevelUpperDistanceCm: _toDouble(upperMap['distanceCm'], 999),
      waterLevelUpperFull: upperMap['full'] == true,
      isDraining: data['isDraining'] == true,
      isFilling: data['isFilling'] == true,
      autoMode: data['autoMode'] == true,
      state: data['state']?.toString() ?? '-',
      duration: _toInt(data['durasi'] ?? data['duration']),
      timestamp: data['timestamp'] ?? data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'trigger': trigger,
      'turbidity': turbidity,
      'ammonia': ammonia,
      'turbidityRaw': turbidityRaw,
      'ammoniaRaw': ammoniaRaw,
      'turbidityVoltage': turbidityVoltage,
      'ammoniaVoltage': ammoniaVoltage,
      'waterLevelLower': {
        'percent': waterLevelLowerPercent,
        'raw': waterLevelLowerRaw,
        'voltage': waterLevelLowerVoltage,
        'empty': waterLevelLowerEmpty,
      },
      'waterLevelUpper': {
        'distanceCm': waterLevelUpperDistanceCm,
        'full': waterLevelUpperFull,
      },
      'isDraining': isDraining,
      'isFilling': isFilling,
      'autoMode': autoMode,
      'state': state,
      'duration': duration,
      'timestamp': timestamp,
    };
  }

  DateTime get dateTime => timestamp.toDate();

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }

  static double _toDouble(dynamic value, [double defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int _toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
