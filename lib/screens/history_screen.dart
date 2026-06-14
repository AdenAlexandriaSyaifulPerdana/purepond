import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:purepond_app/models/history_model.dart';
import 'package:purepond_app/services/firestore_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatTrigger(String trigger) {
    final lower = trigger.toLowerCase();

    if (lower.contains('ammonia') && lower.contains('turbidity')) {
      return 'Amonia & Kekeruhan';
    }

    if (lower.contains('ammonia') || lower.contains('amonia')) {
      return 'Amonia';
    }

    if (lower.contains('turbidity') || lower.contains('kekeruhan')) {
      return 'Kekeruhan';
    }

    return trigger.isEmpty ? '-' : trigger;
  }

  Color _triggerColor(String trigger) {
    final lower = trigger.toLowerCase();

    if (lower.contains('ammonia') && lower.contains('turbidity')) {
      return Colors.deepOrange;
    }

    if (lower.contains('ammonia') || lower.contains('amonia')) {
      return Colors.purple;
    }

    if (lower.contains('turbidity') || lower.contains('kekeruhan')) {
      return Colors.blue;
    }

    return Colors.grey;
  }

  IconData _triggerIcon(String trigger) {
    final lower = trigger.toLowerCase();

    if (lower.contains('ammonia') && lower.contains('turbidity')) {
      return Icons.warning_amber_rounded;
    }

    if (lower.contains('ammonia') || lower.contains('amonia')) {
      return Icons.science;
    }

    if (lower.contains('turbidity') || lower.contains('kekeruhan')) {
      return Icons.water_drop;
    }

    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Riwayat Pengurasan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
      ),
      body: StreamBuilder<List<HistoryModel>>(
        stream: firestoreService.getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildMessage(
              icon: Icons.error_outline,
              title: 'Gagal memuat riwayat',
              subtitle: snapshot.error.toString(),
              color: Colors.red,
            );
          }

          final histories = snapshot.data ?? [];

          if (histories.isEmpty) {
            return _buildMessage(
              icon: Icons.history,
              title: 'Belum ada riwayat',
              subtitle:
                  'Riwayat akan muncul setelah sistem selesai melakukan pengurasan otomatis.',
              color: Colors.blue,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: histories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final history = histories[index];
              return _buildHistoryCard(context, history);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 74,
              color: color.withOpacity(0.75),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryModel history) {
    final color = _triggerColor(history.trigger);
    final date = _formatDate(history.dateTime);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showHistoryDetail(context, history),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _triggerIcon(history.trigger),
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengurasan ${history.type}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pemicu: ${_formatTrigger(history.trigger)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetail(BuildContext context, HistoryModel history) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final color = _triggerColor(history.trigger);

        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _triggerIcon(history.trigger),
                        color: color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Pengurasan',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          Text(
                            _formatDate(history.dateTime),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('Kualitas Air Saat Pengurasan'),
                _detailRow(
                  'Amonia',
                  '${history.ammonia.toStringAsFixed(2)} ppm',
                ),
                _detailRow(
                  'Amonia Raw',
                  history.ammoniaRaw.toString(),
                ),
                _detailRow(
                  'Kekeruhan',
                  '${history.turbidity.toStringAsFixed(1)} NTU',
                ),
                _detailRow(
                  'Kekeruhan Raw',
                  history.turbidityRaw.toString(),
                ),
                const SizedBox(height: 14),
                _sectionTitle('Ketinggian Air'),
                _detailRow(
                  'Water Level Bawah',
                  history.waterLevelLowerEmpty ? 'Kosong' : 'Ada air',
                ),
                _detailRow(
                  'Voltage Bawah',
                  '${history.waterLevelLowerVoltage.toStringAsFixed(2)} V',
                ),
                _detailRow(
                  'Persentase Bawah',
                  '${history.waterLevelLowerPercent.toStringAsFixed(0)}%',
                ),
                _detailRow(
                  'Ultrasonic Atas',
                  '${history.waterLevelUpperDistanceCm.toStringAsFixed(1)} cm',
                ),
                _detailRow(
                  'Status Atas',
                  history.waterLevelUpperFull ? 'Penuh' : 'Belum penuh',
                ),
                const SizedBox(height: 14),
                _sectionTitle('Status Sistem'),
                _detailRow(
                  'Pemicu',
                  _formatTrigger(history.trigger),
                ),
                _detailRow(
                  'State',
                  history.state,
                ),
                _detailRow(
                  'Pompa',
                  history.isFilling ? 'ON' : 'OFF',
                ),
                _detailRow(
                  'Servo',
                  history.isDraining ? 'BUKA' : 'TUTUP',
                ),
                _detailRow(
                  'Auto Mode',
                  history.autoMode ? 'ON' : 'OFF',
                ),
                _detailRow(
                  'Durasi',
                  history.duration > 0 ? '${history.duration} detik' : '-',
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade900,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
