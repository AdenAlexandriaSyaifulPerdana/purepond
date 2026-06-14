import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:purepond_app/models/sensor_model.dart';
import 'package:purepond_app/services/notification_service.dart';
import 'package:purepond_app/services/realtime_service.dart';

class EventService {
  final RealtimeService realtimeService;
  final NotificationService notificationService;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<SensorModel>? _subscription;
  bool _started = false;

  static const double ammoniaLimit = 0.50;
  static const double turbidityLimit = 120.0;

  static const double ammoniaCritical = ammoniaLimit * 1.5; // 0.75 ppm
  static const double turbidityCritical = turbidityLimit * 1.5; // 180 NTU

  String _currentWarningKey = '';
  String _currentDrainKey = '';

  bool _lastDrainCycleLocked = false;
  bool _historySavedForCurrentCycle = false;

  SensorModel? _drainStartSensor;
  DateTime? _drainStartedAt;
  int? _drainStartMillis;

  EventService({
    required this.realtimeService,
    required this.notificationService,
  });

  void startListening() {
    if (_started) return;

    _started = true;

    _subscription = realtimeService.getSensorStream().listen((sensor) {
      unawaited(_handleSensor(sensor));
    });
  }

  Future<void> _handleSensor(SensorModel sensor) async {
    final analysis = _analyze(sensor);

    await _handleWarningNotification(sensor, analysis);

    // Simpan data awal siklus dulu.
    // Ini penting agar parameter drain tidak menjadi unknown.
    await _handleDrainHistory(sensor);

    await _handleDrainNotification(sensor);

    _lastDrainCycleLocked = sensor.drainCycleLocked;
  }

  // =====================================================
  // ================= WARNING NOTIFICATION ===============
  // =====================================================

  Future<void> _handleWarningNotification(
    SensorModel sensor,
    _QualityAnalysis analysis,
  ) async {
    // Warning muncul ketika 1 sensor melewati 100%.
    // Walaupun nilainya langsung masuk 150%, warning tetap boleh muncul dulu.
    // Tapi kalau siklus pengurasan sudah berjalan, warning tidak perlu diulang.
    if (analysis.warningCondition && !sensor.drainCycleLocked) {
      if (_currentWarningKey != analysis.warningKey) {
        _currentWarningKey = analysis.warningKey;

        final title = 'Peringatan Kualitas Air';
        final body = '${analysis.parameterLabel} melebihi batas normal. '
            'Nilai saat ini ${analysis.value.toStringAsFixed(2)} ${analysis.unit}.';

        await _saveNotification(
          title: title,
          body: body,
          type: 'warning',
          parameter: analysis.parameter,
          value: analysis.value,
          threshold: analysis.warningThreshold,
        );

        await notificationService.showLocalNotification(
          title: title,
          body: body,
          payload: jsonEncode({
            'type': 'warning',
            'parameter': analysis.parameter,
          }),
        );
      }
    } else {
      if (!sensor.drainCycleLocked) {
        _currentWarningKey = '';
      }
    }
  }

  // =====================================================
  // ================= DRAIN NOTIFICATION =================
  // =====================================================

  Future<void> _handleDrainNotification(SensorModel sensor) async {
    final bool drainCycleJustStarted =
        !_lastDrainCycleLocked && sensor.drainCycleLocked;

    if (!drainCycleJustStarted) {
      // Kalau autoMode OFF, ESP32 tidak akan menguras.
      // Tapi aplikasi tetap boleh memberi notifikasi kualitas air buruk.
      final analysis = _analyze(sensor);

      if (!sensor.autoMode && analysis.drainCondition) {
        final key = 'drain-needed-auto-off-${analysis.parameter}';

        if (_currentDrainKey != key) {
          _currentDrainKey = key;

          final title = 'Kualitas Air Buruk';
          final body = '${analysis.parameterLabel} melewati batas pengurasan, '
              'tetapi otomatisasi sedang mati.';

          await _saveNotification(
            title: title,
            body: body,
            type: 'drain',
            parameter: analysis.parameter,
            value: analysis.value,
            threshold: analysis.drainThreshold,
          );

          await notificationService.showLocalNotification(
            title: title,
            body: body,
            payload: jsonEncode({
              'type': 'drain',
              'parameter': analysis.parameter,
            }),
          );
        }
      }

      if (!analysis.drainCondition && !sensor.drainCycleLocked) {
        _currentDrainKey = '';
      }

      return;
    }

    // Saat ESP32 benar-benar mulai pengurasan,
    // gunakan data awal siklus agar parameter tidak unknown.
    final triggerSensor = _drainStartSensor ?? sensor;
    final analysis = _analyze(triggerSensor);

    final String parameter = analysis.parameter == 'unknown'
        ? _detectTriggerFromReason(sensor.drainTriggerReason)
        : analysis.parameter;

    final String safeParameter = parameter == 'unknown'
        ? _detectTriggerFromSensor(triggerSensor)
        : parameter;

    final double value = _valueByParameter(safeParameter, triggerSensor);
    final double threshold = _drainThresholdByParameter(safeParameter);

    final String label = _labelByParameter(safeParameter);
    final String unit = _unitByParameter(safeParameter);

    final key = 'drain-cycle-$safeParameter-${sensor.drainTriggerReason}';

    if (_currentDrainKey != key) {
      _currentDrainKey = key;

      final title = 'Pengurasan Otomatis Dimulai';

      final body = sensor.drainTriggerReason.isNotEmpty
          ? sensor.drainTriggerReason
          : '$label melewati batas pengurasan. Sistem mulai melakukan pengurasan otomatis.';

      await _saveNotification(
        title: title,
        body: body,
        type: 'drain',
        parameter: safeParameter,
        value: value,
        threshold: threshold,
      );

      await notificationService.showLocalNotification(
        title: title,
        body: unit.isEmpty
            ? body
            : '$body Nilai saat ini ${value.toStringAsFixed(2)} $unit.',
        payload: jsonEncode({
          'type': 'drain',
          'parameter': safeParameter,
        }),
      );
    }
  }

  // =====================================================
  // ================= HISTORY ===========================
  // =====================================================

  Future<void> _handleDrainHistory(SensorModel sensor) async {
    if (!_lastDrainCycleLocked && sensor.drainCycleLocked) {
      _drainStartSensor = sensor;
      _drainStartedAt = DateTime.now();
      _drainStartMillis = sensor.millis;
      _historySavedForCurrentCycle = false;
      return;
    }

    if (sensor.drainCycleLocked && _drainStartSensor == null) {
      _drainStartSensor = sensor;
      _drainStartedAt = DateTime.now();
      _drainStartMillis = sensor.millis;
      _historySavedForCurrentCycle = false;
      return;
    }

    if (_lastDrainCycleLocked &&
        !sensor.drainCycleLocked &&
        !_historySavedForCurrentCycle) {
      final startSensor = _drainStartSensor ?? sensor;
      final startMillis = _drainStartMillis ?? sensor.millis;

      int duration = 0;

      if (sensor.millis > startMillis) {
        duration = ((sensor.millis - startMillis) / 1000).round();
      } else if (_drainStartedAt != null) {
        duration = DateTime.now().difference(_drainStartedAt!).inSeconds;
      }

      final trigger = startSensor.drainTriggerReason.isEmpty
          ? _detectTriggerFromSensor(startSensor)
          : startSensor.drainTriggerReason;

      await _firestore.collection('history').add({
        'type': 'Otomatis',
        'tipe': 'Otomatis',
        'trigger': trigger,
        'pemicu': trigger,
        'ammonia': startSensor.ammonia,
        'ammoniaRaw': startSensor.ammoniaRaw,
        'ammoniaVoltage': startSensor.ammoniaVoltage,
        'turbidity': startSensor.turbidity,
        'turbidityRaw': startSensor.turbidityRaw,
        'turbidityVoltage': startSensor.turbidityVoltage,
        'waterLevelLower': {
          'raw': startSensor.waterLevelLowerRaw,
          'voltage': startSensor.waterLevelLowerVoltage,
          'percent': startSensor.waterLevelLowerPercent,
          'empty': startSensor.waterLevelLowerEmpty,
          'detected': startSensor.waterLevelLower,
        },
        'waterLevelUpper': {
          'distanceCm': sensor.waterLevelUpperDistanceCm,
          'full': sensor.waterLevelUpper,
          'status': sensor.waterLevelUpperStatus,
        },
        'startData': startSensor.toFirestore(),
        'finishData': sensor.toFirestore(),
        'isDraining': sensor.isDraining,
        'isFilling': sensor.isFilling,
        'autoMode': sensor.autoMode,
        'state': sensor.state,
        'duration': duration,
        'durasi': duration,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _historySavedForCurrentCycle = true;
      _drainStartSensor = null;
      _drainStartedAt = null;
      _drainStartMillis = null;
      _currentDrainKey = '';
    }
  }

  // =====================================================
  // ================= SAVE FIRESTORE =====================
  // =====================================================

  Future<void> _saveNotification({
    required String title,
    required String body,
    required String type,
    required String parameter,
    required double value,
    required double threshold,
  }) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'judul': title,
      'body': body,
      'isi': body,
      'type': type,
      'parameter': parameter,
      'value': value,
      'nilai': value,
      'threshold': threshold,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =====================================================
  // ================= ANALYSIS ==========================
  // =====================================================

  _QualityAnalysis _analyze(SensorModel sensor) {
    final bool ammoniaOver100 =
        sensor.ammonia >= ammoniaLimit || sensor.ammoniaBad;

    final bool turbidityOver100 =
        sensor.turbidity > turbidityLimit || sensor.turbidityBad;

    final bool ammoniaOver150 = sensor.ammonia >= ammoniaCritical;
    final bool turbidityOver150 = sensor.turbidity > turbidityCritical;

    final int over100Count =
        (ammoniaOver100 ? 1 : 0) + (turbidityOver100 ? 1 : 0);

    final bool drainCondition = ammoniaOver150 ||
        turbidityOver150 ||
        over100Count >= 2 ||
        sensor.needDrain;

    final bool warningCondition = over100Count == 1;

    String parameter = 'unknown';

    if (ammoniaOver100 && turbidityOver100) {
      parameter = 'both';
    } else if (ammoniaOver100) {
      parameter = 'ammonia';
    } else if (turbidityOver100) {
      parameter = 'turbidity';
    }

    if (parameter == 'unknown' && sensor.drainTriggerReason.isNotEmpty) {
      parameter = _detectTriggerFromReason(sensor.drainTriggerReason);
    }

    final value = _valueByParameter(parameter, sensor);
    final warningThreshold = _warningThresholdByParameter(parameter);
    final drainThreshold = _drainThresholdByParameter(parameter);

    return _QualityAnalysis(
      warningCondition: warningCondition,
      drainCondition: drainCondition,
      warningKey: warningCondition ? 'warning-$parameter' : '',
      parameter: parameter,
      parameterLabel: _labelByParameter(parameter),
      unit: _unitByParameter(parameter),
      value: value,
      warningThreshold: warningThreshold,
      drainThreshold: drainThreshold,
    );
  }

  // =====================================================
  // ================= PARAMETER HELPER ==================
  // =====================================================

  String _detectTriggerFromSensor(SensorModel sensor) {
    final ammoniaOver100 = sensor.ammonia >= ammoniaLimit || sensor.ammoniaBad;
    final turbidityOver100 =
        sensor.turbidity > turbidityLimit || sensor.turbidityBad;

    if (ammoniaOver100 && turbidityOver100) {
      return 'both';
    }

    if (ammoniaOver100) {
      return 'ammonia';
    }

    if (turbidityOver100) {
      return 'turbidity';
    }

    return _detectTriggerFromReason(sensor.drainTriggerReason);
  }

  String _detectTriggerFromReason(String reason) {
    final lower = reason.toLowerCase();

    final hasAmmonia = lower.contains('amonia') ||
        lower.contains('ammonia') ||
        lower.contains('ppm');

    final hasTurbidity = lower.contains('turbidity') ||
        lower.contains('kekeruhan') ||
        lower.contains('keruh') ||
        lower.contains('ntu');

    if (hasAmmonia && hasTurbidity) {
      return 'both';
    }

    if (hasAmmonia) {
      return 'ammonia';
    }

    if (hasTurbidity) {
      return 'turbidity';
    }

    return 'unknown';
  }

  String _labelByParameter(String parameter) {
    switch (parameter) {
      case 'ammonia':
        return 'Amonia';
      case 'turbidity':
        return 'Kekeruhan';
      case 'both':
        return 'Amonia dan kekeruhan';
      default:
        return 'Kualitas air';
    }
  }

  String _unitByParameter(String parameter) {
    switch (parameter) {
      case 'ammonia':
        return 'ppm';
      case 'turbidity':
        return 'NTU';
      default:
        return '';
    }
  }

  double _valueByParameter(String parameter, SensorModel sensor) {
    switch (parameter) {
      case 'ammonia':
        return sensor.ammonia;
      case 'turbidity':
        return sensor.turbidity;
      case 'both':
        // Model notifikasi kamu hanya punya 1 nilai.
        // Untuk both, nilai utama diambil dari turbidity agar tidak 0.
        return sensor.turbidity > 0 ? sensor.turbidity : sensor.ammonia;
      default:
        if (sensor.turbidity > turbidityLimit) return sensor.turbidity;
        if (sensor.ammonia >= ammoniaLimit) return sensor.ammonia;
        return 0;
    }
  }

  double _warningThresholdByParameter(String parameter) {
    switch (parameter) {
      case 'ammonia':
        return ammoniaLimit;
      case 'turbidity':
        return turbidityLimit;
      case 'both':
        return turbidityLimit;
      default:
        return 0;
    }
  }

  double _drainThresholdByParameter(String parameter) {
    switch (parameter) {
      case 'ammonia':
        return ammoniaCritical;
      case 'turbidity':
        return turbidityCritical;
      case 'both':
        return turbidityCritical;
      default:
        return 0;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

class _QualityAnalysis {
  final bool warningCondition;
  final bool drainCondition;

  final String warningKey;

  final String parameter;
  final String parameterLabel;
  final String unit;

  final double value;
  final double warningThreshold;
  final double drainThreshold;

  _QualityAnalysis({
    required this.warningCondition,
    required this.drainCondition,
    required this.warningKey,
    required this.parameter,
    required this.parameterLabel,
    required this.unit,
    required this.value,
    required this.warningThreshold,
    required this.drainThreshold,
  });
}
