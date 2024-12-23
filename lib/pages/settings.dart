
import 'package:flutter/material.dart';
import 'package:irrigation_app/pages/profile.dart';

import 'about.dart';
import 'device_id.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 30),
        backgroundColor: Color(0xdd222222),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 50, horizontal: 10),
          child: ListView(
            children: [
              ListTile(
                title: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 20),),
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                },
              ),
              ListTile(
                title: const Text('Device ID', style: TextStyle(color: Colors.white, fontSize: 20),),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DeviceIdPage()),
                  );
                },
              ),
              ListTile(
                title: const Text('About', style: TextStyle(color: Colors.white,fontSize: 20),),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ],
          ),
      ),
      ),
    );
  }
}
