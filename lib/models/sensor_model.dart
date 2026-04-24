import 'package:cloud_firestore/cloud_firestore.dart';

class SensorModel {
  final double turbidity;
  final double ammonia;
  final double ph;
  final bool waterLevelUpper;
  final bool waterLevelLower;
  final bool isDraining;
  final bool isFilling;
  final String? fcmToken;
  final Timestamp? lastWaterChange;
  final Timestamp updatedAt;
  final String? secretKey;

  SensorModel({
    required this.turbidity,
    required this.ammonia,
    required this.ph,
    required this.waterLevelUpper,
    required this.waterLevelLower,
    required this.isDraining,
    required this.isFilling,
    this.fcmToken,
    this.lastWaterChange,
    required this.updatedAt,
    this.secretKey,
  });

  factory SensorModel.fromFirestore(Map<String, dynamic> data) {
    return SensorModel(
      turbidity: (data['turbidity'] ?? 0).toDouble(),
      ammonia: (data['ammonia'] ?? 0).toDouble(),
      ph: (data['ph'] ?? 7).toDouble(),
      waterLevelUpper: data['waterLevelUpper'] ?? true,
      waterLevelLower: data['waterLevelLower'] ?? true,
      isDraining: data['isDraining'] ?? false,
      isFilling: data['isFilling'] ?? false,
      fcmToken: data['fcmToken'],
      lastWaterChange: data['lastWaterChange'],
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      secretKey: data['secretKey'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'turbidity': turbidity,
      'ammonia': ammonia,
      'ph': ph,
      'waterLevelUpper': waterLevelUpper,
      'waterLevelLower': waterLevelLower,
      'isDraining': isDraining,
      'isFilling': isFilling,
      'fcmToken': fcmToken,
      'lastWaterChange': lastWaterChange,
      'updatedAt': updatedAt,
      'secretKey': secretKey,
    };
  }

  static Map<String, dynamic> esp32Format({
    required double turbidity,
    required double ammonia,
    required double ph,
    required bool waterLevelUpper,
    required bool waterLevelLower,
    required bool isDraining,
    required bool isFilling,
  }) {
    return {
      'turbidity': turbidity,
      'ammonia': ammonia,
      'ph': ph,
      'waterLevelUpper': waterLevelUpper,
      'waterLevelLower': waterLevelLower,
      'isDraining': isDraining,
      'isFilling': isFilling,
      'secretKey': 'PurePondESP32_2026_SecureKey',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static SensorModel empty() {
    return SensorModel(
      turbidity: 0,
      ammonia: 0,
      ph: 7,
      waterLevelUpper: true,
      waterLevelLower: true,
      isDraining: false,
      isFilling: false,
      updatedAt: Timestamp.now(),
    );
  }
}
