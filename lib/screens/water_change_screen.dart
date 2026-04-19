import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterChangeScreen extends StatefulWidget {
  final double currentTurbidity;
  final double currentAmmonia;
  final double currentPh;

  const WaterChangeScreen({
    super.key,
    required this.currentTurbidity,
    required this.currentAmmonia,
    required this.currentPh,
  });

  @override
  State<WaterChangeScreen> createState() => _WaterChangeScreenState();
}

class _WaterChangeScreenState extends State<WaterChangeScreen> {
  // Threshold settings
  double _turbidityThreshold = 20.0;
  double _ammoniaThreshold = 0.5;
  double _phMinThreshold = 6.5;
  double _phMaxThreshold = 8.5;

  int _delayMinutes = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Atur Threshold Pergantian Air',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status
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
                  Text(
                    'Status Air Saat Ini',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCurrentStatus(
                        'Kekeruhan',
                        '${widget.currentTurbidity.toStringAsFixed(1)} NTU',
                        widget.currentTurbidity > _turbidityThreshold
                            ? Colors.red
                            : Colors.green,
                      ),
                      _buildCurrentStatus(
                        'Amonia',
                        '${widget.currentAmmonia.toStringAsFixed(2)} ppm',
                        widget.currentAmmonia > _ammoniaThreshold
                            ? Colors.red
                            : Colors.green,
                      ),
                      _buildCurrentStatus(
                        'pH',
                        widget.currentPh.toStringAsFixed(1),
                        (widget.currentPh < _phMinThreshold ||
                                widget.currentPh > _phMaxThreshold)
                            ? Colors.red
                            : Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Threshold Settings
            Text(
              'Pengaturan Batas (Threshold)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pergantian air akan dilakukan otomatis saat parameter melebihi batas',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Turbidity Threshold
            _buildThresholdCard(
              'Kekeruhan',
              'Pergantian air jika kekeruhan > ${_turbidityThreshold.toStringAsFixed(0)} NTU',
              _turbidityThreshold,
              10,
              50,
              (value) => setState(() => _turbidityThreshold = value),
              'NTU',
              Icons.waves,
              Colors.brown,
            ),

            const SizedBox(height: 16),

            // Ammonia Threshold
            _buildThresholdCard(
              'Amonia',
              'Pergantian air jika amonia > ${_ammoniaThreshold.toStringAsFixed(1)} ppm',
              _ammoniaThreshold,
              0.1,
              2.0,
              (value) => setState(() => _ammoniaThreshold = value),
              'ppm',
              Icons.science,
              Colors.purple,
            ),

            const SizedBox(height: 16),

            // pH Range
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.opacity, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'pH Air',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Range pH Ideal: ${_phMinThreshold.toStringAsFixed(1)} - ${_phMaxThreshold.toStringAsFixed(1)}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: RangeValues(_phMinThreshold, _phMaxThreshold),
                    min: 5.0,
                    max: 9.0,
                    divisions: 40,
                    labels: RangeLabels(
                      _phMinThreshold.toStringAsFixed(1),
                      _phMaxThreshold.toStringAsFixed(1),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _phMinThreshold = values.start;
                        _phMaxThreshold = values.end;
                      });
                    },
                    activeColor: Colors.blue.shade700,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Asam (5.0)',
                          style: GoogleFonts.poppins(fontSize: 11)),
                      Text('Basa (9.0)',
                          style: GoogleFonts.poppins(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pergantian air jika pH < ${_phMinThreshold.toStringAsFixed(1)} atau > ${_phMaxThreshold.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Delay Settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'Waktu Tunda',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pergantian air akan dilakukan $_delayMinutes menit setelah parameter melebihi batas',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '$_delayMinutes menit',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: _delayMinutes.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: '$_delayMinutes menit',
                          onChanged: (value) {
                            setState(() {
                              _delayMinutes = value.toInt();
                            });
                          },
                          activeColor: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Jumlah air yang diganti akan disesuaikan otomatis berdasarkan pembacaan sensor water level.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pengaturan threshold berhasil disimpan!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'SIMPAN PENGATURAN',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdCard(
    String title,
    String description,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String unit,
    IconData icon,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.shade700),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                value.toStringAsFixed(title == 'Amonia' ? 1 : 0),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions:
                      ((max - min) / (title == 'Amonia' ? 0.1 : 5)).round(),
                  label: value.toStringAsFixed(title == 'Amonia' ? 1 : 0),
                  onChanged: onChanged,
                  activeColor: color.shade700,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$min $unit', style: GoogleFonts.poppins(fontSize: 11)),
              Text('$max $unit', style: GoogleFonts.poppins(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
