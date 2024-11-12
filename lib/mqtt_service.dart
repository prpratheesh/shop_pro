import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String broker = 'YOUR_BROKER_URL'; // e.g., 'broker.hivemq.com'
  final int port = 1883; // Default MQTT port
  final String clientIdentifier = 'your_client_id';
  MqttServerClient client;

  MqttService() {
    client = MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.onDisconnected = onDisconnected;
  }

  Future<void> connect() async {
    try {
      await client.connect();
      print('Connected to MQTT broker');
    } catch (e) {
      print('Error connecting to MQTT broker: $e');
      client.disconnect();
    }
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload;
      final String message =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $message from topic: ${c[0].topic}>');
      // Handle the received message as needed
    });
  }

  void disconnect() {
    client.disconnect();
  }
}
