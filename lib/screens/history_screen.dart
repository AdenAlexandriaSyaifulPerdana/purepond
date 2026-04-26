import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purepond_app/services/firestore_service.dart';
import 'package:purepond_app/models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<List<HistoryModel>>(
      stream: firestoreService.getHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final historyData = snapshot.data ?? [];

        // Hitung statistik Minggu Ini & Bulan Ini
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final monthStart = DateTime(now.year, now.month, 1);

        final thisWeekCount = historyData.where((item) {
          final itemDate = item.timestamp.toDate();
          return itemDate.isAfter(weekStart) ||
              itemDate.isAtSameMomentAs(weekStart);
        }).length;

        final thisMonthCount = historyData.where((item) {
          final itemDate = item.timestamp.toDate();
          return itemDate.isAfter(monthStart) ||
              itemDate.isAtSameMomentAs(monthStart);
        }).length;

        return Column(
          children: [
            // Statistics Cards
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Minggu ini',
                      '$thisWeekCount',
                      Icons.calendar_today,
                      Colors.blue,
                      'x',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Bulan ini',
                      '$thisMonthCount',
                      Icons.calendar_month,
                      Colors.green,
                      'x',
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // History List
            Expanded(
              child: historyData.isEmpty
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
                            'Belum ada history pengurasan',
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
                      itemCount: historyData.length,
                      itemBuilder: (context, index) {
                        final item = historyData[index];
                        final date = item.timestamp.toDate();
                        final isExpanded = _expandedIndex == index;

                        // Cek parameter yang tinggi
                        final turbidityHigh = item.turbidity > 20.0;
                        final ammoniaHigh = item.ammonia > 0.5;
                        final phAbnormal = item.ph < 6.5 || item.ph > 8.5;

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Icon
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.water_drop,
                                              color: Colors.green.shade700,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Date & Time
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
                                          // Badge (HANYA OTOMATIS)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Otomatis',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Expand icon
                                          Icon(
                                            isExpanded
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            color: Colors.grey.shade500,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Pemicu & Durasi
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildDetailItem(
                                            Icons.info_outline,
                                            'Pemicu',
                                            item.trigger,
                                          ),
                                          _buildDetailItem(
                                            Icons.timer,
                                            'Durasi',
                                            '${item.duration} menit',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Expanded detail
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Divider(height: 1),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Icon(Icons.analytics_outlined,
                                              size: 18,
                                              color: Colors.grey.shade700),
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildParameterCard(
                                              'Kekeruhan',
                                              '${item.turbidity.toStringAsFixed(1)} NTU',
                                              Icons.waves,
                                              Colors.brown,
                                              turbidityHigh,
                                              'Normal: < 20 NTU',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildParameterCard(
                                              'Amonia',
                                              '${item.ammonia.toStringAsFixed(2)} ppm',
                                              Icons.air,
                                              Colors.purple,
                                              ammoniaHigh,
                                              'Normal: < 0.5 ppm',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildParameterCard(
                                              'pH',
                                              item.ph.toStringAsFixed(1),
                                              Icons.science,
                                              Colors.blue,
                                              phAbnormal,
                                              'Normal: 6.5 - 8.5',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: (turbidityHigh ||
                                                  ammoniaHigh ||
                                                  phAbnormal)
                                              ? Colors.orange.shade50
                                              : Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                                _getConclusionText(
                                                    turbidityHigh,
                                                    ammoniaHigh,
                                                    phAbnormal),
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
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String suffix) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(suffix,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(label,
            style:
                GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade500)),
        Text(value,
            style:
                GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildParameterCard(String label, String value, IconData icon,
      MaterialColor color, bool isAbnormal, String normalRange) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAbnormal ? Colors.red.shade200 : Colors.grey.shade200,
          width: isAbnormal ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isAbnormal ? Colors.red.shade50 : color.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon,
                size: 18,
                color: isAbnormal ? Colors.red.shade700 : color.shade700),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color:
                      isAbnormal ? Colors.red.shade700 : Colors.grey.shade800)),
          const SizedBox(height: 4),
          Text(normalRange,
              style:
                  GoogleFonts.poppins(fontSize: 8, color: Colors.grey.shade500),
              textAlign: TextAlign.center),
          if (isAbnormal) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Tinggi',
                  style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700)),
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
      return 'Pengurasan otomatis dipicu karena ${issues[0]} melebihi batas normal.';
    } else if (issues.length == 2) {
      return 'Pengurasan otomatis dipicu karena ${issues[0]} dan ${issues[1]} melebihi batas normal.';
    } else {
      return 'Pengurasan otomatis dipicu karena kekeruhan, amonia, dan pH melebihi batas normal.';
    }
  }
}
