import 'package:intl/date_time_patterns.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'logger.dart';

class MqttService {
  final String broker;
  final String clientIdentifier;
  final int port;
  final Function(String) onNotificationReceived; // Callback function
  late MqttServerClient client;

  // StreamController to emit connection status events
  final StreamController<MqttConnectionStatus> _statusController = StreamController.broadcast();
  Timer? _reconnectTimer; // Timer for retrying connection

  MqttService({
    required this.broker,
    required this.clientIdentifier,
    required this.onNotificationReceived, // Require the callback
    this.port = 1883,
  }) {
    client = MqttServerClient(broker, clientIdentifier);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = onPong;
  }

  Future<void> connect() async {
    client.port = port;
    client.logging(on: false); // Enable logging for debugging
    client.keepAlivePeriod = 60;
    client.autoReconnect = false; // Disable autoReconnect to manage it manually
    client.resubscribeOnAutoReconnect = false;

    try {
      await client.connect();
    } catch (e) {
      Logger.log('ERROR CONNECTING TO BROKER. $e', level: LogLevel.critical);
      disconnect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      Logger.log('CONNECTED TO MQTT BROKER.', level: LogLevel.debug);
      subscribe('system/notifications'); // Subscribe to the specific topic
      _statusController.add(MqttConnectionStatus.connected);
      _reconnectTimer?.cancel(); // Cancel any existing timer on successful connection
    } else {
      Logger.log('FAILED TO CONNECT TO BROKER. ${client.connectionStatus}', level: LogLevel.error);
      _statusController.add(MqttConnectionStatus.disconnected);
      // Start reconnection attempts
      startReconnectTimer();
    }

    // Listen for incoming messages
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>>? messages) {
      if (messages == null) return;
      for (var receivedMessage in messages) {
        final MqttPublishMessage mqttMessage = receivedMessage.payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(mqttMessage.payload.message);
        _handleNotification(payload);
      }
    });
  }

  void subscribe(String topic, [MqttQos qos = MqttQos.atLeastOnce]) {
    client.subscribe(topic, qos);
    Logger.log('SUBSCRIBED TO TOPIC. $topic', level: LogLevel.debug);
  }

  void onConnected() {
    Logger.log('CLIENT CONNECTED.', level: LogLevel.debug);
  }

  void onDisconnected() {
    Logger.log('DISCONNECTED FROM MQTT BROKER.', level: LogLevel.warning);
    _statusController.add(MqttConnectionStatus.disconnected);
    // Start the reconnection timer
    startReconnectTimer();
  }

  void onSubscribed(String topic) {
    Logger.log('SUCCESSFULLY SUBSCRIBED TO $topic', level: LogLevel.debug);
  }

  void onSubscribeFail(String topic) {
    Logger.log('FAILED TO SUBSCRIBE TO $topic', level: LogLevel.error);
  }

  void onPong() {
    DateTime utcNow = DateTime.now().toUtc();
    Logger.log('PING RESPONSE RECEIVED FROM SERVER AT $utcNow', level: LogLevel.debug);
  }

  void startReconnectTimer() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;

    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        Logger.log('ATTEMPTING TO RECONNECT.', level: LogLevel.warning);
        await connect();
        if (client.connectionStatus?.state == MqttConnectionState.connected) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    client.disconnect();
  }

  /// Publish a message to a given topic with QoS 1 and retain set to true
  Future<void> publishMessage(String topic, String message) async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final MqttClientPayloadBuilder payloadBuilder = MqttClientPayloadBuilder();
      payloadBuilder.addString(message); // Add your message to the payload

      // Publish the message with QoS 1 and retain set to true
      client.publishMessage(
        topic,
        MqttQos.atLeastOnce, // QoS 1
        payloadBuilder.payload!,
        retain: false, // Retain the message
      );
      Logger.log('MESSAGE PUBLISHED TO TOPIC: $topic, MESSAGE: $message', level: LogLevel.debug);
    } else {
      Logger.log('CLIENT NOT CONNECTED, CANNOT PUBLISH MESSAGE.', level: LogLevel.error);
    }
  }

  Stream<MqttConnectionStatus> get statusStream => _statusController.stream;

  Stream<List<MqttReceivedMessage<MqttMessage>>> get messageStream {
    return client.updates!;
  }

  void _handleNotification(String notification) {
    onNotificationReceived(notification); // Invoke the callback
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _statusController.close();
    client.disconnect();
  }
}

// Define the connection status enumeration
enum MqttConnectionStatus {
  connected,
  disconnected,
  error,
}