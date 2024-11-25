import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        title: const Text('About the app'),
        foregroundColor: Colors.white,
        backgroundColor: Color(0xdd222222),
      ),
      body: Container(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width/30, vertical: MediaQuery.of(context).size.height/60),
          child: const Text(
            'v.1.0.0',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      )
    );
  }
}