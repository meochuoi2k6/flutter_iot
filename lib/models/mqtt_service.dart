import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';

class MqttService {
  late MqttServerClient client;
  bool isConnected = false;

  Future<void> connect(String topic, Function(String) onMessageReceived) async {
    // 1. RANDOM CLIENT ID: Tránh tuyệt đối việc bị trùng ID với MQTT Explorer
    String clientId = 'WinApp_${DateTime.now().millisecondsSinceEpoch}';

    // 2. DÙNG MOSQUITTO WEBSOCKET (PORT 8080)
    // Server này cực kỳ ổn định, không chặn firewall, không drop kết nối ảo
    client = MqttServerClient.withPort('ws://test.mosquitto.org', clientId, 8080);
    
    client.useWebSocket = true;
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.connectTimeoutPeriod = 10000;

    // Mosquitto không cần setProtocolV311 cầu kỳ, nó tự nhận diện rất tốt
    
    client.onConnected = () => print('MQTT: Đã kết nối thành công (Mosquitto WS)!');
    client.onDisconnected = () => print('MQTT: Đã ngắt kết nối');
    
    // Cấu hình tin nhắn chào hỏi
    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean() // Xóa sạch session cũ
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      print('MQTT: Đang kết nối đến ws://test.mosquitto.org:8080 ...');
      await client.connect();
    } on Exception catch (e) {
      print('MQTT: Lỗi kết nối - $e');
      client.disconnect();
    }

    // 3. CHECK KỸ TRẠNG THÁI TRƯỚC KHI SUBSCRIBE (Tránh lỗi bạn nhắc ở mục 3)
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      isConnected = true;
      print('MQTT: Kết nối OK');
      
      // Subscribe
      print('MQTT: Đang đăng ký topic $topic ...');
      client.subscribe(topic, MqttQos.atMostOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
        final String pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        print('MQTT: Nhận được tin nhắn: $pt');
        onMessageReceived(pt);
      });
    } else {
      print('MQTT: Kết nối thất bại: ${client.connectionStatus!.state}');
      client.disconnect();
    }
  }

  void disconnect() {
    client.disconnect();
    isConnected = false;
  }
}