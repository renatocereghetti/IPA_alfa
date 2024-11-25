
import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class Esp32ControlPage extends StatefulWidget {
  const Esp32ControlPage({super.key});

  @override
  _Esp32ControlPageState createState() => _Esp32ControlPageState();
}

class _Esp32ControlPageState extends State<Esp32ControlPage> {
  final MqttService mqttService = MqttService();
  String deviceID = '';
  String status = 'Waiting for data...';
  String autoWateringTime = '';

  @override
  void initState() {
    super.initState();
    mqttService.connect().then((_) {
      mqttService.subscribeToTopic('esp32/+/data');
      mqttService.listenToMessages((topic, message) {
        setState(() {
          status = message; // Update the status with the received message
        });
      });
    });
  }

  void sendManualCommand(String command) {
    if (deviceID.isNotEmpty) {
      mqttService.publishMessage('esp32/$deviceID/control', command);
    }
  }

  void sendAutoCommand(String time) {
    if (deviceID.isNotEmpty) {
      mqttService.publishMessage('esp32/$deviceID/control', time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Device Data: $status'),
            TextField(
              decoration: InputDecoration(labelText: 'Device ID'),
              onChanged: (value) {
                setState(() {
                  deviceID = value;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => sendManualCommand('start'),
                  child: Text('Start Watering'),
                ),
                ElevatedButton(
                  onPressed: () => sendManualCommand('stop'),
                  child: Text('Stop Watering'),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(labelText: 'Auto Watering Time (sec)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  autoWateringTime = value;
                });
              }
            ),
            ElevatedButton(
              onPressed: () => sendAutoCommand(autoWateringTime),
              child: Text('Auto Watering for $autoWateringTime sec'),
            ),
          ],
        ),
      ),
    );
  }
}
