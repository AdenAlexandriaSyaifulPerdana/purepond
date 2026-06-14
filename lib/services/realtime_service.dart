import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:purepond_app/models/sensor_model.dart';

class RealtimeService {
  static const String databaseUrl =
      'https://purepond-67695-default-rtdb.asia-southeast1.firebasedatabase.app/';

  FirebaseDatabase get _database {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
  }

  DatabaseReference get _currentRef {
    return _database.ref('realtime/current');
  }

  Stream<SensorModel> getSensorStream() {
    return _currentRef.onValue.map((event) {
      final snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return SensorModel.empty();
      }

      try {
        final data = _convertToStringDynamicMap(snapshot.value);
        return SensorModel.fromRealtimeDB(data);
      } catch (e) {
        return SensorModel.empty();
      }
    }).handleError((error) {
      return SensorModel.empty();
    });
  }

  Future<SensorModel> getSensorOnce() async {
    try {
      final snapshot = await _currentRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        return SensorModel.empty();
      }

      final data = _convertToStringDynamicMap(snapshot.value);
      return SensorModel.fromRealtimeDB(data);
    } catch (e) {
      return SensorModel.empty();
    }
  }

  Future<void> updateAutoMode(bool value) async {
    await _currentRef.update({
      'autoMode': value,
    });
  }

  Map<String, dynamic> _convertToStringDynamicMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) {
        return MapEntry(
          key.toString(),
          _convertValue(val),
        );
      });
    }

    return {};
  }

  dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return value.map((key, val) {
        return MapEntry(
          key.toString(),
          _convertValue(val),
        );
      });
    }

    if (value is List) {
      return value.map(_convertValue).toList();
    }

    return value;
  }
}
