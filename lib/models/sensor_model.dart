class SensorModel {
  final double turbidity;
  final double ammonia;

  final int turbidityRaw;
  final int ammoniaRaw;

  final double turbidityVoltage;
  final double ammoniaVoltage;

  final double waterDistanceCm;
  final double waterPercent;
  final bool waterFull;
  final bool waterEmpty;
  final String waterStatus;

  final bool waterLevelUpper;
  final bool waterLevelLower;

  final double waterLevelUpperDistanceCm;
  final String waterLevelUpperStatus;

  final double waterLevelLowerPercent;
  final int waterLevelLowerRaw;
  final double waterLevelLowerVoltage;
  final bool waterLevelLowerEmpty;

  final bool autoMode;
  final bool isDraining;
  final bool isFilling;

  final bool drainCycleLocked;
  final String drainTriggerReason;
  final String state;

  final bool needDrain;
  final bool ammoniaBad;
  final bool turbidityBad;

  final bool wifiConnected;
  final int millis;

  SensorModel({
    required this.turbidity,
    required this.ammonia,
    required this.turbidityRaw,
    required this.ammoniaRaw,
    required this.turbidityVoltage,
    required this.ammoniaVoltage,
    required this.waterDistanceCm,
    required this.waterPercent,
    required this.waterFull,
    required this.waterEmpty,
    required this.waterStatus,
    required this.waterLevelUpper,
    required this.waterLevelLower,
    required this.waterLevelUpperDistanceCm,
    required this.waterLevelUpperStatus,
    required this.waterLevelLowerPercent,
    required this.waterLevelLowerRaw,
    required this.waterLevelLowerVoltage,
    required this.waterLevelLowerEmpty,
    required this.autoMode,
    required this.isDraining,
    required this.isFilling,
    required this.drainCycleLocked,
    required this.drainTriggerReason,
    required this.state,
    required this.needDrain,
    required this.ammoniaBad,
    required this.turbidityBad,
    required this.wifiConnected,
    required this.millis,
  });

  factory SensorModel.empty() {
    return SensorModel(
      turbidity: 0,
      ammonia: 0,
      turbidityRaw: 0,
      ammoniaRaw: 0,
      turbidityVoltage: 0,
      ammoniaVoltage: 0,
      waterDistanceCm: 999,
      waterPercent: 0,
      waterFull: false,
      waterEmpty: false,
      waterStatus: 'not_detected',
      waterLevelUpper: false,
      waterLevelLower: false,
      waterLevelUpperDistanceCm: 999,
      waterLevelUpperStatus: 'not_detected',
      waterLevelLowerPercent: 0,
      waterLevelLowerRaw: 0,
      waterLevelLowerVoltage: 0,
      waterLevelLowerEmpty: false,
      autoMode: true,
      isDraining: false,
      isFilling: false,
      drainCycleLocked: false,
      drainTriggerReason: '',
      state: 'UNKNOWN',
      needDrain: false,
      ammoniaBad: false,
      turbidityBad: false,
      wifiConnected: false,
      millis: 0,
    );
  }

  factory SensorModel.fromRealtimeDB(Map<String, dynamic> data) {
    final turbidityMap = _toMap(data['turbidity']);
    final ammoniaMap = _toMap(data['ammonia']);
    final waterMap = _toMap(data['waterLevel']);
    final lowerMap = _toMap(data['waterLevelLower']);
    final upperMap = _toMap(data['waterLevelUpper']);
    final systemMap = _toMap(data['system']);

    final double distance = _toDouble(
      waterMap['distanceCm'] ?? upperMap['distanceCm'],
      999,
    );

    final double percent = _toDouble(
      waterMap['percent'] ?? lowerMap['percent'],
      0,
    );

    final bool full =
        waterMap['full'] == true || upperMap['full'] == true || distance <= 3.0;

    final bool empty = waterMap['empty'] == true ||
        lowerMap['empty'] == true ||
        distance >= 12.0;

    final String status = waterMap['status']?.toString() ??
        (distance >= 999
            ? 'not_detected'
            : full
                ? 'full'
                : empty
                    ? 'empty'
                    : 'normal');

    return SensorModel(
      turbidity: _toDouble(turbidityMap['value']),
      ammonia: _toDouble(ammoniaMap['value']),
      turbidityRaw: _toInt(turbidityMap['raw']),
      ammoniaRaw: _toInt(ammoniaMap['raw']),
      turbidityVoltage: _toDouble(turbidityMap['voltage']),
      ammoniaVoltage: _toDouble(ammoniaMap['voltage']),
      waterDistanceCm: distance,
      waterPercent: percent,
      waterFull: full,
      waterEmpty: empty,
      waterStatus: status,
      waterLevelUpper: full,
      waterLevelLower: !empty,
      waterLevelUpperDistanceCm: distance,
      waterLevelUpperStatus: status,
      waterLevelLowerPercent: percent,
      waterLevelLowerRaw: _toInt(lowerMap['raw']),
      waterLevelLowerVoltage: _toDouble(lowerMap['voltage']),
      waterLevelLowerEmpty: empty,
      autoMode: data['autoMode'] == null ? true : data['autoMode'] == true,
      isDraining: data['isDraining'] == true,
      isFilling: data['isFilling'] == true,
      drainCycleLocked: data['drainCycleLocked'] == true,
      drainTriggerReason: data['drainTriggerReason']?.toString() ?? '',
      state: data['state']?.toString() ?? 'UNKNOWN',
      needDrain: data['needDrain'] == true || data['drainCondition'] == true,
      ammoniaBad: data['ammoniaBad'] == true,
      turbidityBad: data['turbidityBad'] == true,
      wifiConnected: systemMap['wifiConnected'] == true,
      millis: _toInt(systemMap['millis']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'turbidity': turbidity,
      'ammonia': ammonia,
      'turbidityRaw': turbidityRaw,
      'ammoniaRaw': ammoniaRaw,
      'turbidityVoltage': turbidityVoltage,
      'ammoniaVoltage': ammoniaVoltage,
      'waterLevel': {
        'distanceCm': waterDistanceCm,
        'percent': waterPercent,
        'full': waterFull,
        'empty': waterEmpty,
        'status': waterStatus,
      },
      'waterLevelUpper': waterLevelUpper,
      'waterLevelLower': waterLevelLower,
      'waterLevelUpperDistanceCm': waterLevelUpperDistanceCm,
      'waterLevelUpperStatus': waterLevelUpperStatus,
      'waterLevelLowerPercent': waterLevelLowerPercent,
      'waterLevelLowerRaw': waterLevelLowerRaw,
      'waterLevelLowerVoltage': waterLevelLowerVoltage,
      'waterLevelLowerEmpty': waterLevelLowerEmpty,
      'autoMode': autoMode,
      'isDraining': isDraining,
      'isFilling': isFilling,
      'drainCycleLocked': drainCycleLocked,
      'drainTriggerReason': drainTriggerReason,
      'state': state,
      'needDrain': needDrain,
      'ammoniaBad': ammoniaBad,
      'turbidityBad': turbidityBad,
      'wifiConnected': wifiConnected,
      'millis': millis,
    };
  }

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
