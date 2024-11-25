import 'package:flutter/material.dart';
import 'package:irrigation_app/pages/analytics.dart';
import 'package:irrigation_app/pages/dashboard.dart';
import 'package:irrigation_app/pages/settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>{
  int _currentIndex = 1;
  List<Widget> _pages = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String deviceID = '';

  Future<void> _loadDeviceId() async {
    deviceID = await _storage.read(key: 'deviceId') ?? '';
  }

  @override
  initState(){
    super.initState();
    _loadDeviceId();

    _pages = [
      const AnalyticsPage(),
      const DashboardPage(),
      const SettingsPage(),
    ];
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(
          color: Color(0xdd222222),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(MediaQuery.of(context).size.width/10),
            topLeft: Radius.circular(MediaQuery.of(context).size.width/10),
            bottomRight: Radius.circular(MediaQuery.of(context).size.width/10),
            bottomLeft: Radius.circular(MediaQuery.of(context).size.width/10),
          ),
        ),
        child: Theme(
          data: ThemeData(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            fixedColor: Colors.white,
            unselectedItemColor: Colors.grey,
            elevation: 0.0,
            iconSize: 32,
            currentIndex: _currentIndex,
            onTap: (index){
              setState(() {
                _currentIndex = index;
                _loadDeviceId();
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Files'),
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings')
            ],
          ),
        ),
      )
    );
  }
}
