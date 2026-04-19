import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Data history dengan detail parameter sebelum dikuras
  final List<Map<String, dynamic>> _historyData = [
    {
      'date': DateTime.now().subtract(const Duration(days: 0, hours: 2)),
      'type': 'Otomatis',
      'trigger': 'Kekeruhan tinggi',
      'turbidity': 35.5,
      'ammonia': 0.32,
      'ph': 7.2,
      'duration': '15 menit',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'Manual',
      'trigger': 'Pengguna',
      'turbidity': 18.0,
      'ammonia': 0.21,
      'ph': 7.5,
      'duration': '12 menit',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'type': 'Otomatis',
      'trigger': 'Amonia tinggi',
      'turbidity': 15.0,
      'ammonia': 0.85,
      'ph': 7.0,
      'duration': '15 menit',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'type': 'Otomatis',
      'trigger': 'pH tidak normal',
      'turbidity': 12.0,
      'ammonia': 0.30,
      'ph': 8.7,
      'duration': '15 menit',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'type': 'Manual',
      'trigger': 'Pengguna',
      'turbidity': 20.0,
      'ammonia': 0.40,
      'ph': 7.3,
      'duration': '10 menit',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 13)),
      'type': 'Otomatis',
      'trigger': 'Kekeruhan tinggi',
      'turbidity': 42.0,
      'ammonia': 0.50,
      'ph': 7.1,
      'duration': '15 menit',
    },
  ];

  String _selectedFilter = 'Semua';
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final filteredData = _selectedFilter == 'Semua'
        ? _historyData
        : _historyData
            .where((item) => item['type'] == _selectedFilter)
            .toList();

    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                'Filter:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                children: ['Semua', 'Otomatis', 'Manual'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return FilterChip(
                    label: Text(
                      filter,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.blue.shade700,
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Statistics Cards
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${_historyData.length}x',
                  Icons.repeat,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Otomatis',
                  '${_historyData.where((h) => h['type'] == 'Otomatis').length}x',
                  Icons.auto_mode,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Manual',
                  '${_historyData.where((h) => h['type'] == 'Manual').length}x',
                  Icons.touch_app,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),

        // History List
        Expanded(
          child: filteredData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada history',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final item = filteredData[index];
                    final date = item['date'] as DateTime;
                    final isAuto = item['type'] == 'Otomatis';
                    final isExpanded = _expandedIndex == index;

                    // Cek parameter yang tinggi
                    final turbidityHigh = item['turbidity'] > 20.0;
                    final ammoniaHigh = item['ammonia'] > 0.5;
                    final phAbnormal = item['ph'] < 6.5 || item['ph'] > 8.5;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedIndex = isExpanded ? null : index;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isAuto
                                              ? Colors.green.shade50
                                              : Colors.orange.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isAuto
                                              ? Icons.auto_mode
                                              : Icons.touch_app,
                                          color: isAuto
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${date.day}/${date.month}/${date.year}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAuto
                                              ? Colors.green.shade100
                                              : Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          item['type'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isAuto
                                                ? Colors.green.shade700
                                                : Colors.orange.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: Colors.grey.shade500,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildDetailItem(
                                        Icons.info_outline,
                                        'Pemicu',
                                        item['trigger'],
                                      ),
                                      _buildDetailItem(
                                        Icons.timer,
                                        'Durasi',
                                        item['duration'],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Expanded content - Detail Parameter Sebelum Dikuras
                          if (isExpanded)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),

                                  // Title
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.analytics_outlined,
                                        size: 18,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Parameter Sebelum Dikuras:',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Parameter Cards
                                  Row(
                                    children: [
                                      // Kekeruhan
                                      Expanded(
                                        child: _buildParameterCard(
                                          'Kekeruhan',
                                          '${item['turbidity'].toStringAsFixed(1)} NTU',
                                          Icons.waves,
                                          Colors.brown,
                                          turbidityHigh,
                                          'Normal: < 20 NTU',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Amonia
                                      Expanded(
                                        child: _buildParameterCard(
                                          'Amonia',
                                          '${item['ammonia'].toStringAsFixed(2)} ppm',
                                          Icons.air,
                                          Colors.purple,
                                          ammoniaHigh,
                                          'Normal: < 0.5 ppm',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // pH
                                      Expanded(
                                        child: _buildParameterCard(
                                          'pH',
                                          item['ph'].toStringAsFixed(1),
                                          Icons.science,
                                          Colors.blue,
                                          phAbnormal,
                                          'Normal: 6.5 - 8.5',
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Kesimpulan
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (turbidityHigh ||
                                              ammoniaHigh ||
                                              phAbnormal)
                                          ? Colors.orange.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: (turbidityHigh ||
                                                ammoniaHigh ||
                                                phAbnormal)
                                            ? Colors.orange.shade200
                                            : Colors.green.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          (turbidityHigh ||
                                                  ammoniaHigh ||
                                                  phAbnormal)
                                              ? Icons.warning_amber
                                              : Icons.check_circle,
                                          size: 18,
                                          color: (turbidityHigh ||
                                                  ammoniaHigh ||
                                                  phAbnormal)
                                              ? Colors.orange.shade700
                                              : Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _getConclusionText(turbidityHigh,
                                                ammoniaHigh, phAbnormal),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: (turbidityHigh ||
                                                      ammoniaHigh ||
                                                      phAbnormal)
                                                  ? Colors.orange.shade900
                                                  : Colors.green.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildParameterCard(String label, String value, IconData icon,
      MaterialColor color, bool isAbnormal, String normalRange) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAbnormal ? Colors.red.shade200 : Colors.grey.shade200,
          width: isAbnormal ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isAbnormal ? Colors.red.shade50 : color.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isAbnormal ? Colors.red.shade700 : color.shade700,
            ),
          ),
          const SizedBox(height: 8),
          // Label
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          // Value
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isAbnormal ? Colors.red.shade700 : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          // Normal Range
          Text(
            normalRange,
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          // Status Badge if abnormal
          if (isAbnormal) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Melebihi Batas',
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getConclusionText(
      bool turbidityHigh, bool ammoniaHigh, bool phAbnormal) {
    List<String> issues = [];
    if (turbidityHigh) issues.add('kekeruhan');
    if (ammoniaHigh) issues.add('amonia');
    if (phAbnormal) issues.add('pH');

    if (issues.isEmpty) {
      return 'Semua parameter dalam batas normal saat pengurasan dilakukan.';
    } else if (issues.length == 1) {
      return 'Pengurasan dipicu karena ${issues[0]} melebihi batas normal.';
    } else if (issues.length == 2) {
      return 'Pengurasan dipicu karena ${issues[0]} dan ${issues[1]} melebihi batas normal.';
    } else {
      return 'Pengurasan dipicu karena kekeruhan, amonia, dan pH melebihi batas normal.';
    }
  }
}
