import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile'),
        foregroundColor: Colors.white,
        backgroundColor: Color(0xdd222222),
      ),
        body: Center(
          child: Text('Coming soon ...', style: TextStyle(color: Colors.white, fontSize: 20),),
        )
    );
  }
}