import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

var connectedClient = false;

class MqttService {
  final String broker = '51.154.70.191';
  final int port = 1883;
  late MqttServerClient client;

  MqttService() {
    final String clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.onDisconnected = onDisconnected;
  }

  Future<void> connect() async {
    try {
      print('Connecting to the MQTT broker...');
      await client.connect();

      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('Connected to the MQTT broker at $broker');
        connectedClient = true;
      } else {
        print('Connection failed: ${client.connectionStatus}');
        client.disconnect();
      }
    } catch (e) {
      print('Connection error: $e');
      client.disconnect();
    }
  }

  void onDisconnected() {
    print('Disconnected from the MQTT broker');
    connectedClient = false;
    // You can add reconnection logic here if needed
  }

  void publishMessage(String topic, String message) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('Published message: $message to topic: $topic');
    } else {
      print('Cannot publish message, client is not connected');
    }
  }

  void subscribeToTopic(String topic) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.subscribe(topic, MqttQos.atLeastOnce);
      print('Subscribed to topic: $topic');
    } else {
      print('Cannot subscribe to topic, client is not connected');
    }
  }

  // Handle receiving messages
  void listenToMessages(Function(String topic, String message) onMessageReceived) {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      onMessageReceived(c[0].topic, payload);
    });
  }

  void onConnected() {
    print('Connected to MQTT Broker');
  }
}
