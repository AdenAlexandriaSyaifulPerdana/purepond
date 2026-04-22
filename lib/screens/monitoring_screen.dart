import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purepond_app/widgets/monitoring_card.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  // Data monitoring dari sensor
  double _turbidity = 25.0; // Kekeruhan (NTU) - Sensor Turbidity
  double _ammonia = 0.8; // Amonia (ppm) - Sensor MQ-135
  double _phLevel = 8.2; // pH - Sensor E-201C

  // Status water level
  bool _upperSensorActive = true; // Sensor atas (penuh)
  bool _lowerSensorActive = true; // Sensor bawah

  // Status sistem
  bool _autoChangeEnabled = true;
  bool _isDraining = false; // Sedang membuang air
  bool _isFilling = false; // Sedang mengisi air

  DateTime _lastWaterChange = DateTime.now().subtract(const Duration(hours: 6));

  // Threshold - STATIS (tidak bisa diubah user)
  static const double _turbidityThreshold = 20.0;
  static const double _ammoniaThreshold = 0.5;
  static const double _phMinThreshold = 6.5;
  static const double _phMaxThreshold = 8.5;
  static const int _delayMinutes = 5; // Waktu tunda statis

  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _turbidity = 15.0 + (DateTime.now().second % 30).toDouble();
      _ammonia = 0.2 + (DateTime.now().second % 15) / 10;
      _phLevel = 6.8 + (DateTime.now().second % 25) / 10;

      if (_turbidity > _turbidityThreshold) {
        _lowerSensorActive = DateTime.now().second % 2 == 0;
      } else {
        _lowerSensorActive = true;
      }

      _isRefreshing = false;
    });
  }

  bool get _needWaterChange {
    return _turbidity > _turbidityThreshold ||
        _ammonia > _ammoniaThreshold ||
        _phLevel < _phMinThreshold ||
        _phLevel > _phMaxThreshold;
  }

  Color _getTurbidityColor() {
    if (_turbidity > 50) return Colors.red;
    if (_turbidity > _turbidityThreshold) return Colors.orange;
    return Colors.green;
  }

  Color _getAmmoniaColor() {
    if (_ammonia > 1.0) return Colors.red;
    if (_ammonia > _ammoniaThreshold) return Colors.orange;
    return Colors.green;
  }

  Color _getPhColor() {
    if (_phLevel < 6.0 || _phLevel > 9.0) return Colors.red;
    if (_phLevel < _phMinThreshold || _phLevel > _phMaxThreshold)
      return Colors.orange;
    return Colors.green;
  }

  String _getTurbidityStatus() {
    if (_turbidity > 50) return 'Sangat Keruh';
    if (_turbidity > _turbidityThreshold) return 'Keruh';
    return 'Jernih';
  }

  String _getAmmoniaStatus() {
    if (_ammonia > 1.0) return 'Berbahaya';
    if (_ammonia > _ammoniaThreshold) return 'Tinggi';
    return 'Aman';
  }

  String _getPhStatus() {
    if (_phLevel < 6.0) return 'Sangat Asam';
    if (_phLevel > 9.0) return 'Sangat Basa';
    if (_phLevel < _phMinThreshold) return 'Asam';
    if (_phLevel > _phMaxThreshold) return 'Basa';
    return 'Normal';
  }

  String _getWaterQualityStatus() {
    int badParams = 0;
    if (_getTurbidityColor() == Colors.red) badParams += 2;
    if (_getTurbidityColor() == Colors.orange) badParams++;
    if (_getAmmoniaColor() == Colors.red) badParams += 2;
    if (_getAmmoniaColor() == Colors.orange) badParams++;
    if (_getPhColor() == Colors.red) badParams += 2;
    if (_getPhColor() == Colors.orange) badParams++;

    if (badParams == 0) return "OPTIMAL";
    if (badParams <= 1) return "BAIK";
    if (badParams <= 3) return "PERLU PERHATIAN";
    return "KRITIS";
  }

  Color _getQualityStatusColor() {
    switch (_getWaterQualityStatus()) {
      case "OPTIMAL":
        return Colors.green;
      case "BAIK":
        return Colors.lightGreen;
      case "PERLU PERHATIAN":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _needWaterChange
                      ? [Colors.red.shade600, Colors.orange.shade400]
                      : [Colors.blue.shade600, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _needWaterChange
                        ? Colors.red.shade200
                        : Colors.blue.shade200,
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
                            color: _getQualityStatusColor(),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getWaterQualityStatus(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_needWaterChange) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.warning,
                                  color: Colors.white, size: 18),
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
                      ],
                    ),
                  ),
                  Icon(
                    _needWaterChange ? Icons.warning : Icons.water_drop,
                    size: 60,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Water Level Status (2 Sensor)
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
                          _upperSensorActive,
                          'Penuh',
                          'Kosong',
                          Icons.water_drop,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildSensorStatus(
                          'Sensor Bawah',
                          _lowerSensorActive,
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
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lowerSensorActive
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
            ),

            const SizedBox(height: 20),

            // System Status (Draining/Filling)
            if (_isDraining || _isFilling)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDraining
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDraining
                        ? Colors.orange.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDraining ? Icons.water_damage : Icons.water_drop,
                      color: _isDraining
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
                            _isDraining
                                ? 'Sedang Membuang Air'
                                : 'Sedang Mengisi Air',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isDraining
                                  ? Colors.orange.shade900
                                  : Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isDraining
                                  ? Colors.orange.shade400
                                  : Colors.green.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (_isDraining || _isFilling) const SizedBox(height: 20),

            // Parameter Kualitas Air
            Text(
              'Parameter Kualitas Air',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Kekeruhan (Turbidity Sensor)
            MonitoringCard(
              title: 'Kekeruhan',
              value: '${_turbidity.toStringAsFixed(1)} NTU',
              icon: Icons.waves,
              color: _getTurbidityColor(),
              subtitle: _getTurbidityStatus(),
              threshold: _turbidityThreshold,
              currentValue: _turbidity,
              maxValue: 100,
              unit: 'NTU',
              sensorName: 'Turbidity',
            ),

            const SizedBox(height: 12),

            // Amonia (MQ-135)
            MonitoringCard(
              title: 'Amonia',
              value: '${_ammonia.toStringAsFixed(2)} ppm',
              icon: Icons.air,
              color: _getAmmoniaColor(),
              subtitle: _getAmmoniaStatus(),
              threshold: _ammoniaThreshold,
              currentValue: _ammonia,
              maxValue: 2.0,
              unit: 'ppm',
              sensorName: 'MQ-135',
            ),

            const SizedBox(height: 12),

            // pH (E-201C)
            MonitoringCard(
              title: 'pH Air',
              value: _phLevel.toStringAsFixed(1),
              icon: Icons.science,
              color: _getPhColor(),
              subtitle: _getPhStatus(),
              threshold: _phMinThreshold,
              thresholdMax: _phMaxThreshold,
              currentValue: _phLevel,
              maxValue: 14,
              unit: 'pH',
              sensorName: 'E-201C',
            ),

            const SizedBox(height: 24),

            // Sistem Otomatisasi
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
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Status Auto Change
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
                              _autoChangeEnabled ? 'Aktif' : 'Nonaktif',
                              style: GoogleFonts.poppins(
                                color: _autoChangeEnabled
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 14,
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
                        },
                        activeColor: Colors.green.shade700,
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Alur Otomatisasi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alur Otomatisasi:',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFlowStep(
                            '1. Air keruh/amonia tinggi/pH tidak normal', true),
                        _buildFlowStep(
                            '2. Pompa buang air menyala', _needWaterChange),
                        _buildFlowStep(
                            '3. Pompa buang mati', !_lowerSensorActive),
                        _buildFlowStep(
                            '4. Pompa isi menyala (dari tandon)', _isFilling),
                        _buildFlowStep('5. Sensor atas terendam pompa isi mati',
                            _upperSensorActive),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Threshold Info (STATIS - Hanya Info)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.settings,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Pengaturan Batas :',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Kekeruhan > $_turbidityThreshold NTU',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          '• Amonia > $_ammoniaThreshold ppm',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          '• pH < $_phMinThreshold atau > $_phMaxThreshold',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          '• Waktu tunda: $_delayMinutes menit',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Trigger Conditions
                  Text(
                    'Status Pemicu Saat Ini:',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTriggerCondition(
                        'Kekeruhan',
                        _turbidity > _turbidityThreshold,
                        '> $_turbidityThreshold NTU',
                      ),
                      const SizedBox(width: 16),
                      _buildTriggerCondition(
                        'Amonia',
                        _ammonia > _ammoniaThreshold,
                        '> $_ammoniaThreshold ppm',
                      ),
                      const SizedBox(width: 16),
                      _buildTriggerCondition(
                        'pH',
                        _phLevel < _phMinThreshold ||
                            _phLevel > _phMaxThreshold,
                        '${_phMinThreshold.toStringAsFixed(1)}-${_phMaxThreshold.toStringAsFixed(1)}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tombol Kuras Manual (Hanya satu tombol)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_isDraining || _isFilling)
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    'Pengurasan Manual',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  content: Text(
                                    'Mulai pengurasan air sekarang?',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Batal',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isDraining = true;
                                          _lastWaterChange = DateTime.now();
                                        });
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Pengurasan dimulai...',
                                              style: GoogleFonts.poppins(),
                                            ),
                                            backgroundColor: Colors.blue,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: Text(
                                        'Mulai',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                      icon: Icon(
                        Icons.water_drop,
                        size: 20,
                        color: (_isDraining || _isFilling)
                            ? Colors.grey
                            : Colors.green.shade700,
                      ),
                      label: Text(
                        _isDraining
                            ? 'Sedang Membuang Air...'
                            : (_isFilling
                                ? 'Sedang Mengisi Air...'
                                : 'Kuras Manual Sekarang'),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(
                          color: (_isDraining || _isFilling)
                              ? Colors.grey
                              : Colors.green.shade700,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Last Activity
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
                    'Pengurasan terakhir: ${_lastWaterChange.day}/${_lastWaterChange.month}/${_lastWaterChange.year} ${_lastWaterChange.hour}:${_lastWaterChange.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatus(String label, bool isActive, String activeText,
      String inactiveText, IconData icon) {
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
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
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

  Widget _buildFlowStep(String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerCondition(String label, bool isTriggered, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTriggered ? Colors.red : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isTriggered ? Colors.red : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
