import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:purepond_app/models/notification_model.dart';
import 'package:purepond_app/services/firestore_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatParameter(String parameter) {
    final lower = parameter.toLowerCase();

    if (lower.contains('ammonia') || lower.contains('amonia')) {
      return 'Amonia';
    }

    if (lower.contains('turbidity') || lower.contains('kekeruhan')) {
      return 'Kekeruhan';
    }

    if (lower.contains('both') || lower.contains('dua')) {
      return 'Amonia & Kekeruhan';
    }

    return parameter.isEmpty ? '-' : parameter;
  }

  String _unit(String parameter) {
    final lower = parameter.toLowerCase();

    if (lower.contains('ammonia') || lower.contains('amonia')) {
      return 'ppm';
    }

    if (lower.contains('turbidity') || lower.contains('kekeruhan')) {
      return 'NTU';
    }

    return '';
  }

  Color _notificationColor(NotificationModel notification) {
    if (notification.isDrainNotification) {
      return Colors.red;
    }

    final parameter = notification.parameter.toLowerCase();

    if (parameter.contains('ammonia') || parameter.contains('amonia')) {
      return Colors.purple;
    }

    if (parameter.contains('turbidity') || parameter.contains('kekeruhan')) {
      return Colors.blue;
    }

    return Colors.orange;
  }

  IconData _notificationIcon(NotificationModel notification) {
    if (notification.isDrainNotification) {
      return Icons.water_damage_rounded;
    }

    final parameter = notification.parameter.toLowerCase();

    if (parameter.contains('ammonia') || parameter.contains('amonia')) {
      return Icons.science;
    }

    if (parameter.contains('turbidity') || parameter.contains('kekeruhan')) {
      return Icons.water_drop;
    }

    return Icons.notifications_active;
  }

  String _typeLabel(NotificationModel notification) {
    if (notification.isDrainNotification) {
      return 'Pengurasan';
    }

    return 'Peringatan';
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
          'Notifikasi',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tandai semua dibaca',
            onPressed: () async {
              await firestoreService.markAllAsRead();
            },
            icon: const Icon(Icons.done_all),
            color: Colors.blue.shade700,
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: firestoreService.getNotificationsStream(),
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
              title: 'Gagal memuat notifikasi',
              subtitle: snapshot.error.toString(),
              color: Colors.red,
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildMessage(
              icon: Icons.notifications_none,
              title: 'Belum ada notifikasi',
              subtitle:
                  'Notifikasi akan muncul saat kualitas air melewati batas.',
              color: Colors.blue,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return _buildNotificationCard(
                context,
                notification,
                firestoreService,
              );
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

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    FirestoreService firestoreService,
  ) {
    final color = _notificationColor(notification);
    final unit = _unit(notification.parameter);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        if (!notification.isRead) {
          await firestoreService.markAsRead(notification.id);
        }

        if (context.mounted) {
          _showNotificationDetail(context, notification);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : color.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _notificationIcon(notification),
                    color: color,
                    size: 28,
                  ),
                ),
                if (!notification.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _typeLabel(notification),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${notification.value.toStringAsFixed(2)} $unit',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

  void _showNotificationDetail(
    BuildContext context,
    NotificationModel notification,
  ) {
    final color = _notificationColor(notification);
    final unit = _unit(notification.parameter);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
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
                        _notificationIcon(notification),
                        color: color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  notification.body,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _detailRow(
                  'Jenis',
                  _typeLabel(notification),
                ),
                _detailRow(
                  'Parameter',
                  _formatParameter(notification.parameter),
                ),
                _detailRow(
                  'Nilai',
                  '${notification.value.toStringAsFixed(2)} $unit',
                ),
                _detailRow(
                  'Batas',
                  '${notification.threshold.toStringAsFixed(2)} $unit',
                ),
                _detailRow(
                  'Waktu',
                  _formatDate(notification.dateTime),
                ),
              ],
            ),
          ),
        );
      },
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
}
