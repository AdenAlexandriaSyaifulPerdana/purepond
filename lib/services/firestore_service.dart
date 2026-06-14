import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purepond_app/models/history_model.dart';
import 'package:purepond_app/models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _historyRef => _firestore.collection('history');

  CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');

  Stream<List<HistoryModel>> getHistoryStream() {
    return _historyRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryModel.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Stream<List<NotificationModel>> getNotificationsStream() {
    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Future<void> markAsRead(String id) async {
    await _notificationsRef.doc(id).update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final snapshot =
        await _notificationsRef.where('isRead', isEqualTo: false).get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<int> getUnreadCount() async {
    final snapshot =
        await _notificationsRef.where('isRead', isEqualTo: false).get();
    return snapshot.docs.length;
  }
}
