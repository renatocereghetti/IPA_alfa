import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdPage extends StatefulWidget {
  const DeviceIdPage({super.key});

  @override
  State<DeviceIdPage> createState() => _DeviceIdPageState();
}

class _DeviceIdPageState extends State<DeviceIdPage> {
  final _deviceIdController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String currentDeviceId = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _saveDeviceId(String deviceId) async {
    await _storage.write(key: 'deviceId', value: deviceId);
    setState(() {
      currentDeviceId = deviceId;
    });
  }

  Future<void> _loadDeviceId() async {
    final storedDeviceId = await _storage.read(key: 'deviceId') ?? 'Not set';
    setState(() {
      currentDeviceId = storedDeviceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        title: const Text('Device ID'),
        foregroundColor: Colors.white,
        backgroundColor: Color(0xdd222222),
      ),
      body: Center(
        child: ListTile(
          title: const Text('Enter Device ID', style: TextStyle(color: Colors.white),),
          subtitle: Column(
            children: [
              TextField(
                controller: _deviceIdController,
                decoration: const InputDecoration(hintText: 'Device ID'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final deviceId = _deviceIdController.text;
                  await _saveDeviceId(deviceId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device ID saved successfully')),
                  );
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 20),
              Text(
                'Current Device ID: $currentDeviceId',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
