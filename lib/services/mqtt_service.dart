import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String _broker = 'YOUR_BROKER_URL'; // Ganti dengan URL dari HiveMQ
  final int _port = 8883; // Port untuk MQTT over TLS (atau 1883 untuk non-TLS)
  final String _username = 'YOUR_USERNAME'; // Jika diperlukan
  final String _password = 'YOUR_PASSWORD'; // Jika diperlukan
  final String _clientId =
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}';

  MqttServerClient? _client;

  // Inisialisasi koneksi
  Future<void> connect() async {
    _client = MqttServerClient(_broker, _clientId);
    _client!.port = _port;
    _client!.secure = true; // Aktifkan jika port 8883
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 30;
    _client!.onDisconnected = _onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .startClean()
        .keepAliveFor(30);
    if (_username.isNotEmpty) {
      connMessage.authenticateAs(_username, _password);
    }
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      print('MQTT Connection error: $e');
      _client!.disconnect();
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT connected');
    } else {
      print('MQTT connection failed');
    }
  }

  // Publish perintah ke ESP32
  void publishCommand(String topic, String message) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('Published to $topic: $message');
    }
  }

  // Subscribe ke topik (jika Flutter juga perlu mendengarkan ESP32)
  void subscribe(String topic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      print('Subscribed to $topic');
    }
  }

  // Callback saat disconnect
  void _onDisconnected() {
    print('MQTT disconnected, attempting reconnect...');
    // Logika reconnect bisa ditambahkan
  }

  // Pastikan untuk disconnect saat tidak digunakan
  void disconnect() {
    _client?.disconnect();
  }
}
