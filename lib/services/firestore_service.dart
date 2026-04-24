import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purepond_app/models/sensor_model.dart';
import 'package:purepond_app/models/history_model.dart';
import 'package:purepond_app/models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _realtimeRef => _firestore.collection('realtime');
  CollectionReference get _historyRef => _firestore.collection('history');
  CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');

  // ========== REALTIME SENSOR ==========

  Stream<SensorModel> getRealtimeStream() {
    return _realtimeRef.doc('current').snapshots().map((snapshot) {
      if (snapshot.exists) {
        return SensorModel.fromFirestore(
            snapshot.data() as Map<String, dynamic>);
      }
      return SensorModel.empty();
    });
  }

  Future<SensorModel> getRealtimeOnce() async {
    final snapshot = await _realtimeRef.doc('current').get();
    if (snapshot.exists) {
      return SensorModel.fromFirestore(snapshot.data() as Map<String, dynamic>);
    }
    return SensorModel.empty();
  }

  Future<void> updateFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _realtimeRef.doc('current').set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> updateLastWaterChange() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _realtimeRef.doc('current').set({
        'lastWaterChange': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ========== HISTORY ==========

  Stream<List<HistoryModel>> getHistoryStream() {
    return _historyRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryModel.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addHistory(HistoryModel history) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _historyRef.add(history.toFirestore());
    }
  }

  // ========== NOTIFICATIONS ==========

  Stream<List<NotificationModel>> getNotificationsStream() {
    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addNotification(NotificationModel notification) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _notificationsRef.add(notification.toFirestore());
    }
  }

  Future<void> markAsRead(String id) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _notificationsRef.doc(id).update({'isRead': true});
    }
  }

  Future<int> getUnreadCount() async {
    final snapshot =
        await _notificationsRef.where('isRead', isEqualTo: false).get();
    return snapshot.docs.length;
  }
}
