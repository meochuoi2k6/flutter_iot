import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  bool isConnected = false;

  Future<void> connect(
    String topic,
    Function(String message) onMessageReceived,
  ) async {
    final clientId =
        'WinApp_${DateTime.now().millisecondsSinceEpoch}';

    // ✅ TCP MQTT (ỔN ĐỊNH NHẤT TRÊN WINDOWS)
    client = MqttServerClient.withPort(
      'test.mosquitto.org',
      clientId,
      1883, // TCP MQTT
    );

    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.connectTimeoutPeriod = 10000;

    client.onConnected = () {
      isConnected = true;
      print('MQTT: ✅ Connected (TCP)');
    };

    client.onDisconnected = () {
      isConnected = false;
      print('MQTT: ❌ Disconnected');
    };

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMess;

    try {
      print('MQTT: 🔌 Connecting TCP...');
      await client.connect();
    } catch (e) {
      print('MQTT: ❌ Connect error: $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state !=
        MqttConnectionState.connected) {
      print('MQTT: ❌ Connection failed');
      client.disconnect();
      return;
    }

    print('MQTT: 📡 Subscribe $topic');
    client.subscribe(topic, MqttQos.atMostOnce);

    client.updates?.listen((events) {
      final recMess =
          events.first.payload as MqttPublishMessage;

      final payload =
          MqttPublishPayload.bytesToStringAsString(
              recMess.payload.message);

      print('MQTT: 📥 $payload');
      onMessageReceived(payload);
    });
  }

  void disconnect() {
    if (isConnected) {
      client.disconnect();
    }
    isConnected = false;
  }
}
