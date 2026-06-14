import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:purepond_app/models/sensor_model.dart';
import 'package:purepond_app/services/realtime_service.dart';
import 'package:purepond_app/widgets/monitoring_card.dart';

enum WaterQualityLevel {
  normal,
  warning,
  critical,
}

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  static const double _turbidityThreshold = 120.0;
  static const double _ammoniaThreshold = 0.50;

  static const double _criticalPercent = 1.5;

  late final Stream<SensorModel> _sensorStream;
  bool _isUpdatingAutoMode = false;

  @override
  void initState() {
    super.initState();

    final realtimeService = Provider.of<RealtimeService>(
      context,
      listen: false,
    );

    _sensorStream = realtimeService.getSensorStream();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorModel>(
      stream: _sensorStream,
      initialData: SensorModel.empty(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Gagal membaca data sensor:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? SensorModel.empty();

        final waterQuality = _checkWaterQuality(data);
        final needWaterChange = waterQuality == WaterQualityLevel.critical;

        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<RealtimeService>(
              context,
              listen: false,
            ).getSensorOnce();
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderStatus(
                  data,
                  waterQuality,
                  needWaterChange,
                ),
                const SizedBox(height: 20),
                _buildWaterLevelStatus(data),
                const SizedBox(height: 20),
                _buildSystemInfo(data),
                const SizedBox(height: 20),
                if (data.isDraining ||
                    data.isFilling ||
                    data.drainCycleLocked) ...[
                  _buildSystemStatus(data),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Parameter Kualitas Air',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                MonitoringCard(
                  title: 'Kekeruhan',
                  value: '${data.turbidity.toStringAsFixed(1)} NTU',
                  icon: Icons.waves,
                  color: _getTurbidityColor(data.turbidity),
                  subtitle: _getTurbidityStatus(data.turbidity),
                  threshold: _turbidityThreshold,
                  currentValue: data.turbidity,
                  maxValue: 200,
                  unit: 'NTU',
                  sensorName: 'Turbidity',
                ),
                const SizedBox(height: 12),
                MonitoringCard(
                  title: 'Amonia',
                  value: '${data.ammonia.toStringAsFixed(2)} ppm',
                  icon: Icons.air,
                  color: _getAmmoniaColor(data.ammonia),
                  subtitle: _getAmmoniaStatus(data.ammonia),
                  threshold: _ammoniaThreshold,
                  currentValue: data.ammonia,
                  maxValue: 1.0,
                  unit: 'ppm',
                  sensorName: 'MQ-135',
                ),
                const SizedBox(height: 24),
                _buildAutomationSystem(data),
              ],
            ),
          ),
        );
      },
    );
  }

  WaterQualityLevel _checkWaterQuality(SensorModel data) {
    final bool ammoniaOver100 = data.ammonia >= _ammoniaThreshold;
    final bool turbidityOver100 = data.turbidity > _turbidityThreshold;

    final bool ammoniaOver150 =
        data.ammonia >= _ammoniaThreshold * _criticalPercent;
    final bool turbidityOver150 =
        data.turbidity > _turbidityThreshold * _criticalPercent;

    final int over100Count =
        (ammoniaOver100 ? 1 : 0) + (turbidityOver100 ? 1 : 0);

    if (ammoniaOver150 || turbidityOver150 || over100Count >= 2) {
      return WaterQualityLevel.critical;
    }

    if (over100Count == 1) {
      return WaterQualityLevel.warning;
    }

    return WaterQualityLevel.normal;
  }

  Widget _buildHeaderStatus(
    SensorModel data,
    WaterQualityLevel quality,
    bool needWaterChange,
  ) {
    Color bgColor;
    String statusText;
    IconData icon;

    switch (quality) {
      case WaterQualityLevel.normal:
        bgColor = Colors.green;
        statusText = 'OPTIMAL';
        icon = Icons.water_drop;
        break;

      case WaterQualityLevel.warning:
        bgColor = Colors.orange;
        statusText = 'PERLU PERHATIAN';
        icon = Icons.info;
        break;

      case WaterQualityLevel.critical:
        bgColor = Colors.red;
        statusText = 'KRITIS - SEGERA KURAS';
        icon = Icons.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: needWaterChange
              ? [Colors.red.shade600, Colors.orange.shade400]
              : quality == WaterQualityLevel.warning
                  ? [Colors.orange.shade600, Colors.orange.shade400]
                  : [Colors.blue.shade600, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Kualitas Air',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitoring berdasarkan turbidity dan amonia.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            size: 56,
            color: Colors.white.withOpacity(0.85),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterLevelStatus(SensorModel data) {
    final String upperDetail = data.waterLevelUpperDistanceCm >= 999
        ? 'Tidak terbaca'
        : '${data.waterLevelUpperDistanceCm.toStringAsFixed(1)} cm';

    final String lowerDetail =
        '${data.waterLevelLowerPercent.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sensors,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Status Water Level Sensor',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSensorStatus(
                  label: 'Sensor Atas',
                  isActive: data.waterLevelUpper,
                  activeText: 'Penuh',
                  inactiveText: 'Belum Penuh',
                  icon: Icons.water_drop,
                  detail: upperDetail,
                ),
              ),
              Container(
                width: 1,
                height: 70,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: _buildSensorStatus(
                  label: 'Sensor Bawah',
                  isActive: data.waterLevelLower,
                  activeText: 'Terendam',
                  inactiveText: 'Tidak Terendam',
                  icon: Icons.water,
                  detail: lowerDetail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorStatus({
    required String label,
    required bool isActive,
    required String activeText,
    required String inactiveText,
    required IconData icon,
    String? detail,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: isActive ? Colors.blue.shade700 : Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isActive ? activeText : inactiveText,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfo(SensorModel data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.blueGrey.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            data.wifiConnected ? Icons.wifi : Icons.wifi_off,
            color: data.wifiConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.wifiConnected
                  ? 'Perangkat ESP32 terhubung ke WiFi'
                  : 'Status WiFi perangkat tidak terdeteksi',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ),
          Text(
            '${(data.millis / 1000).toStringAsFixed(0)} s',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(SensorModel data) {
    String title;
    Color color;
    IconData icon;

    if (data.isDraining) {
      title = 'Sistem sedang menguras air';
      color = Colors.orange;
      icon = Icons.water_damage;
    } else if (data.isFilling) {
      title = 'Sistem sedang mengisi air';
      color = Colors.green;
      icon = Icons.water_drop;
    } else if (data.drainCycleLocked) {
      title = 'Siklus pengurasan sedang berjalan';
      color = Colors.red;
      icon = Icons.sync;
    } else {
      title = 'Sistem dalam keadaan standby';
      color = Colors.blueGrey;
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationSystem(SensorModel data) {
    final bool autoChangeEnabled = data.autoMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sistem Otomatisasi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: autoChangeEnabled
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_mode,
                  color:
                      autoChangeEnabled ? Colors.green.shade700 : Colors.grey,
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
                      autoChangeEnabled
                          ? 'Aktif - sistem dapat menguras otomatis'
                          : 'Nonaktif - monitoring tetap berjalan',
                      style: GoogleFonts.poppins(
                        color: autoChangeEnabled ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _isUpdatingAutoMode
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: autoChangeEnabled,
                      activeThumbColor: Colors.green.shade700,
                      onChanged: (value) async {
                        await _updateAutoMode(value);
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateAutoMode(bool value) async {
    setState(() {
      _isUpdatingAutoMode = true;
    });

    try {
      final realtimeService = Provider.of<RealtimeService>(
        context,
        listen: false,
      );

      await realtimeService.updateAutoMode(value);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Otomatisasi diaktifkan' : 'Otomatisasi dinonaktifkan',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengubah mode otomatis: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAutoMode = false;
        });
      }
    }
  }

  Color _getTurbidityColor(double value) {
    if (value > _turbidityThreshold * _criticalPercent) {
      return Colors.red;
    }

    if (value > _turbidityThreshold) {
      return Colors.orange;
    }

    return Colors.green;
  }

  Color _getAmmoniaColor(double value) {
    if (value >= _ammoniaThreshold * _criticalPercent) {
      return Colors.red;
    }

    if (value >= _ammoniaThreshold) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String _getTurbidityStatus(double value) {
    if (value > _turbidityThreshold * _criticalPercent) {
      return 'Sangat Keruh';
    }

    if (value > _turbidityThreshold) {
      return 'Keruh';
    }

    return 'Jernih';
  }

  String _getAmmoniaStatus(double value) {
    if (value >= _ammoniaThreshold * _criticalPercent) {
      return 'Berbahaya';
    }

    if (value >= _ammoniaThreshold) {
      return 'Di Atas Batas';
    }

    return 'Aman';
  }
}
