import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purepond_app/services/firestore_service.dart';
import 'package:purepond_app/models/sensor_model.dart';
import 'package:purepond_app/widgets/monitoring_card.dart';

// Enum untuk level kualitas air
enum WaterQualityLevel {
  normal, // Level 1 - Hijau
  warning, // Level 2 - Oranye (Notifikasi)
  critical, // Level 3 - Merah (Kuras)
}

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  // Threshold - STATIS
  static const double _turbidityThreshold = 20.0;
  static const double _ammoniaThreshold = 0.5;
  static const double _phMinThreshold = 6.5;
  static const double _phMaxThreshold = 8.5;

  // Persentase untuk level (bisa diubah sesuai kebutuhan)
  static const double _warningPercent = 1.25; // 125% untuk warning
  static const double _criticalPercent = 1.5; // 150% untuk critical

  // Status otomatisasi
  bool _autoChangeEnabled = true;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<SensorModel>(
      stream: firestoreService.getRealtimeStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? SensorModel.empty();
        final waterQuality = _checkWaterQuality(data);
        final needWaterChange = waterQuality == WaterQualityLevel.critical;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Status
                _buildHeaderStatus(data, waterQuality, needWaterChange),

                const SizedBox(height: 20),

                // Water Level Status
                _buildWaterLevelStatus(data),

                const SizedBox(height: 20),

                // System Status (Draining/Filling)
                if (data.isDraining || data.isFilling) _buildSystemStatus(data),

                if (data.isDraining || data.isFilling)
                  const SizedBox(height: 20),

                // Parameter Kualitas Air
                Text(
                  'Parameter Kualitas Air',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Kekeruhan
                MonitoringCard(
                  title: 'Kekeruhan',
                  value: '${data.turbidity.toStringAsFixed(1)} NTU',
                  icon: Icons.waves,
                  color: _getTurbidityColor(data.turbidity),
                  subtitle: _getTurbidityStatus(data.turbidity),
                  threshold: _turbidityThreshold,
                  currentValue: data.turbidity,
                  maxValue: 100,
                  unit: 'NTU',
                  sensorName: 'Turbidity',
                ),

                const SizedBox(height: 12),

                // Amonia
                MonitoringCard(
                  title: 'Amonia',
                  value: '${data.ammonia.toStringAsFixed(2)} ppm',
                  icon: Icons.air,
                  color: _getAmmoniaColor(data.ammonia),
                  subtitle: _getAmmoniaStatus(data.ammonia),
                  threshold: _ammoniaThreshold,
                  currentValue: data.ammonia,
                  maxValue: 2.0,
                  unit: 'ppm',
                  sensorName: 'MQ-135',
                ),

                const SizedBox(height: 12),

                // pH
                MonitoringCard(
                  title: 'pH Air',
                  value: data.ph.toStringAsFixed(1),
                  icon: Icons.science,
                  color: _getPhColor(data.ph),
                  subtitle: _getPhStatus(data.ph),
                  threshold: _phMinThreshold,
                  thresholdMax: _phMaxThreshold,
                  currentValue: data.ph,
                  maxValue: 14,
                  unit: 'pH',
                  sensorName: 'E-201C',
                ),

                const SizedBox(height: 24),

                // Sistem Otomatisasi
                _buildAutomationSystem(data, waterQuality, needWaterChange),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // LOGIKA BERTINGKAT UNTUK KUALITAS AIR
  // ============================================
  WaterQualityLevel _checkWaterQuality(SensorModel data) {
    // Hitung persentase terhadap threshold
    double turbidityPercent = data.turbidity / _turbidityThreshold;
    double ammoniaPercent = data.ammonia / _ammoniaThreshold;

    // Untuk pH (karena range)
    bool phOutOfRange = data.ph < _phMinThreshold || data.ph > _phMaxThreshold;
    double phDeviation = 0;
    if (data.ph < _phMinThreshold) {
      phDeviation = (_phMinThreshold - data.ph) / _phMinThreshold;
    } else if (data.ph > _phMaxThreshold) {
      phDeviation = (data.ph - _phMaxThreshold) / (14 - _phMaxThreshold);
    }

    // Hitung jumlah parameter yang di atas threshold
    int paramsAboveThreshold = 0;
    if (data.turbidity > _turbidityThreshold) paramsAboveThreshold++;
    if (data.ammonia > _ammoniaThreshold) paramsAboveThreshold++;
    if (phOutOfRange) paramsAboveThreshold++;

    // Hitung parameter yang di atas level warning (125%)
    int paramsAboveWarning = 0;
    if (turbidityPercent > _warningPercent) paramsAboveWarning++;
    if (ammoniaPercent > _warningPercent) paramsAboveWarning++;
    if (phDeviation > 0.25) paramsAboveWarning++;

    // Hitung parameter yang di atas level critical (150%)
    bool hasCriticalParam = turbidityPercent > _criticalPercent ||
        ammoniaPercent > _criticalPercent ||
        phDeviation > 0.5;

    // LOGIKA KEPUTUSAN
    if (hasCriticalParam) {
      return WaterQualityLevel.critical; // 1 parameter sangat tinggi
    }

    if (paramsAboveWarning >= 2) {
      return WaterQualityLevel.critical; // 2 parameter cukup tinggi
    }

    if (paramsAboveThreshold >= 3) {
      return WaterQualityLevel.critical; // Semua parameter di atas batas
    }

    if (paramsAboveThreshold >= 1) {
      return WaterQualityLevel.warning; // Notifikasi saja
    }

    return WaterQualityLevel.normal;
  }

  Widget _buildHeaderStatus(
      SensorModel data, WaterQualityLevel quality, bool needWaterChange) {
    Color bgColor;
    String statusText;

    switch (quality) {
      case WaterQualityLevel.normal:
        bgColor = Colors.green;
        statusText = 'OPTIMAL';
        break;
      case WaterQualityLevel.warning:
        bgColor = Colors.orange;
        statusText = 'PERLU PERHATIAN';
        break;
      case WaterQualityLevel.critical:
        bgColor = Colors.red;
        statusText = 'KRITIS - SEGERA KURAS';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: needWaterChange
              ? [Colors.red.shade600, Colors.orange.shade400]
              : (quality == WaterQualityLevel.warning
                  ? [Colors.orange.shade600, Colors.orange.shade400]
                  : [Colors.blue.shade600, Colors.blue.shade400]),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: needWaterChange ? Colors.red.shade200 : Colors.blue.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Kualitas Air',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (needWaterChange) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Air perlu dikuras!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (quality == WaterQualityLevel.warning) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Pantau kualitas air',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Icon(
            needWaterChange
                ? Icons.warning
                : (quality == WaterQualityLevel.warning
                    ? Icons.info
                    : Icons.water_drop),
            size: 60,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPER METHODS (Warna & Status)
  // ============================================
  Color _getTurbidityColor(double value) {
    if (value > _turbidityThreshold * _criticalPercent) return Colors.red;
    if (value > _turbidityThreshold * _warningPercent) return Colors.orange;
    if (value > _turbidityThreshold) return Colors.orange.shade300;
    return Colors.green;
  }

  Color _getAmmoniaColor(double value) {
    if (value > _ammoniaThreshold * _criticalPercent) return Colors.red;
    if (value > _ammoniaThreshold * _warningPercent) return Colors.orange;
    if (value > _ammoniaThreshold) return Colors.orange.shade300;
    return Colors.green;
  }

  Color _getPhColor(double value) {
    if (value < 6.0 || value > 9.0) return Colors.red;
    if (value < _phMinThreshold || value > _phMaxThreshold) {
      // Hitung deviasi untuk warna
      double deviation = 0;
      if (value < _phMinThreshold) {
        deviation = (_phMinThreshold - value) / _phMinThreshold;
      } else {
        deviation = (value - _phMaxThreshold) / (14 - _phMaxThreshold);
      }
      if (deviation > 0.5) return Colors.red;
      if (deviation > 0.25) return Colors.orange;
      return Colors.orange.shade300;
    }
    return Colors.green;
  }

  String _getTurbidityStatus(double value) {
    if (value > _turbidityThreshold * _criticalPercent) return 'Sangat Keruh';
    if (value > _turbidityThreshold * _warningPercent) return 'Keruh Tinggi';
    if (value > _turbidityThreshold) return 'Keruh';
    return 'Jernih';
  }

  String _getAmmoniaStatus(double value) {
    if (value > _ammoniaThreshold * _criticalPercent) return 'Berbahaya';
    if (value > _ammoniaThreshold * _warningPercent) return 'Amonia Tinggi';
    if (value > _ammoniaThreshold) return 'Di Atas Batas';
    return 'Aman';
  }

  String _getPhStatus(double value) {
    if (value < 6.0) return 'Sangat Asam';
    if (value > 9.0) return 'Sangat Basa';
    if (value < _phMinThreshold) return 'Asam';
    if (value > _phMaxThreshold) return 'Basa';
    return 'Normal';
  }

  // ============================================
  // WATER LEVEL STATUS
  // ============================================
  Widget _buildWaterLevelStatus(SensorModel data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                'Status Water Level Sensor',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSensorStatus(
                  'Sensor Atas',
                  data.waterLevelUpper,
                  'Penuh',
                  'Kosong',
                  Icons.water_drop,
                ),
              ),
              Container(width: 1, height: 50, color: Colors.grey.shade300),
              Expanded(
                child: _buildSensorStatus(
                  'Sensor Bawah',
                  data.waterLevelLower,
                  'Terendam',
                  'Tidak Terendam',
                  Icons.water,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.waterLevelLower
                        ? 'Sensor bawah terendam - Air mencukupi'
                        : 'Sensor bawah tidak terendam - Air perlu diisi',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(SensorModel data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.isDraining ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              data.isDraining ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            data.isDraining ? Icons.water_damage : Icons.water_drop,
            color: data.isDraining
                ? Colors.orange.shade700
                : Colors.green.shade700,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.isDraining
                      ? 'Sedang Membuang Air'
                      : 'Sedang Mengisi Air',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: data.isDraining
                        ? Colors.orange.shade900
                        : Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    data.isDraining
                        ? Colors.orange.shade400
                        : Colors.green.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationSystem(
      SensorModel data, WaterQualityLevel quality, bool needWaterChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sistem Otomatisasi',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Toggle Otomatisasi ON/OFF
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _autoChangeEnabled
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_mode,
                      color: _autoChangeEnabled
                          ? Colors.green.shade700
                          : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Otomatisasi Pengurasan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _autoChangeEnabled
                              ? 'Aktif - Sistem akan menguras otomatis'
                              : 'Nonaktif - Sistem tidak akan menguras',
                          style: GoogleFonts.poppins(
                            color:
                                _autoChangeEnabled ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoChangeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoChangeEnabled = value;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Otomatisasi diaktifkan'
                                : 'Otomatisasi dinonaktifkan',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: value ? Colors.green : Colors.orange,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    activeColor: Colors.green.shade700,
                  ),
                ],
              ),

              const Divider(height: 24),

              // Info Threshold & Logika
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logika Otomatisasi:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 1 parameter > 150% batas → Kuras',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.blue.shade900),
                    ),
                    Text(
                      '• 2 parameter > 125% batas → Kuras',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.blue.shade900),
                    ),
                    Text(
                      '• 3 parameter > batas → Kuras',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.blue.shade900),
                    ),
                    Text(
                      '• 1-2 parameter sedikit di atas batas → Notifikasi',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.blue.shade900),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status Pemicu Saat Ini
              Text(
                'Status Pemicu Saat Ini:',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTriggerCondition(
                    'Kekeruhan',
                    data.turbidity > _turbidityThreshold,
                    _getTriggerLevelText(data.turbidity, _turbidityThreshold),
                    '${data.turbidity.toStringAsFixed(1)} / $_turbidityThreshold NTU',
                  ),
                  const SizedBox(width: 8),
                  _buildTriggerCondition(
                    'Amonia',
                    data.ammonia > _ammoniaThreshold,
                    _getTriggerLevelText(data.ammonia, _ammoniaThreshold),
                    '${data.ammonia.toStringAsFixed(2)} / $_ammoniaThreshold ppm',
                  ),
                  const SizedBox(width: 8),
                  _buildTriggerCondition(
                    'pH',
                    data.ph < _phMinThreshold || data.ph > _phMaxThreshold,
                    _getPhTriggerLevel(data.ph),
                    '${data.ph.toStringAsFixed(1)} (${_phMinThreshold.toStringAsFixed(1)}-${_phMaxThreshold.toStringAsFixed(1)})',
                  ),
                ],
              ),

              // Warning jika otomatisasi OFF tapi perlu kuras
              if (!_autoChangeEnabled && needWaterChange) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Air perlu dikuras tetapi otomatisasi nonaktif.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Last Activity
        if (data.lastWaterChange != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Pengurasan terakhir: ${_formatTimestamp(data.lastWaterChange)}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getTriggerLevelText(double value, double threshold) {
    double percent = value / threshold;
    if (percent > _criticalPercent) return 'Sangat Tinggi';
    if (percent > _warningPercent) return 'Tinggi';
    if (percent > 1.0) return 'Di Atas Batas';
    return 'Normal';
  }

  String _getPhTriggerLevel(double value) {
    if (value < _phMinThreshold) {
      double deviation = (_phMinThreshold - value) / _phMinThreshold;
      if (deviation > 0.5) return 'Sangat Asam';
      if (deviation > 0.25) return 'Asam Tinggi';
      return 'Asam';
    } else if (value > _phMaxThreshold) {
      double deviation = (value - _phMaxThreshold) / (14 - _phMaxThreshold);
      if (deviation > 0.5) return 'Sangat Basa';
      if (deviation > 0.25) return 'Basa Tinggi';
      return 'Basa';
    }
    return 'Normal';
  }

  Widget _buildSensorStatus(String label, bool isActive, String activeText,
      String inactiveText, IconData icon) {
    return Column(
      children: [
        Icon(icon,
            size: 32,
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(label,
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isActive ? activeText : inactiveText,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerCondition(
      String label, bool isTriggered, String level, String detail) {
    Color bgColor;
    Color textColor;

    if (level.contains('Sangat')) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else if (level.contains('Tinggi') || level == 'Asam' || level == 'Basa') {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else if (isTriggered) {
      bgColor = Colors.yellow.shade50;
      textColor = Colors.yellow.shade800;
    } else {
      bgColor = Colors.grey.shade50;
      textColor = Colors.grey.shade700;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: textColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                level,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Belum ada';
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
