import 'package:irrigation_app/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'device_id.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:flutter/cupertino.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:math';



class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedTimeUnit = 3;
  List<String> timeUnits = [
    'seconds',
    'minutes',
    'hours',
    'days'
  ];
  bool switchValue = false;
  Offset modeBar = Offset(0,0);
  Color modeColor = Color(0xffD32F2F);
  int _value = 0;
  int _threshold0 = 50;
  int _threshold1 = 50;
  String autoWateringTime = '0';
  String threshold0 = '50';
  String threshold1 = '50';
  String activeThreshold0 = '50';
  String activeThreshold1 = '50';
  int _currentIndex = 0;
  bool _currentIndexData = false;
  final MqttService mqttService = MqttService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String deviceID = '';
  String status0 = '';
  String status1 = '';
  int _currentPlan = 0;
  Duration duration = const Duration(hours: 0, minutes: 0, seconds: 0);
  int interval = 0;
  GlobalKey<ScrollSnapListState> sslKey = GlobalKey();
  GlobalKey<ScrollSnapListState> sslKeyData = GlobalKey();
  String planIsActive0 = 'false';
  String planIsActive1 = 'false';
  int gaugeStyleIndex0 = 0;
  int gaugeStyleIndex1 = 0;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
    _loadIndexStyle();
    _setupMqttConnection();
  }

  Future<void> _setupMqttConnection() async {
    await mqttService.connect();
    mqttService.subscribeToTopic('esp32/$deviceID/+/data');
    mqttService.subscribeToTopic('esp32/$deviceID/+/planIsActive');
    mqttService.listenToMessages((topic, message) {
      if (topic.split('/')[2] == "sensor0") {
        setState(() {
          status0 = message;
        });
      }
      else if (topic.split('/')[2] == "sensor1") {
        setState(() {
          status1 = message;
        });
      }
      else if (topic.split('/')[2] == "pump0"){
        if (topic.split('/')[3] == 'data') {
          setState(() {
            activeThreshold0 = message;
          });
        }
        else if (topic.split('/')[3] == 'planIsActive'){
          setState(() {
            print(planIsActive0);
            planIsActive0 = message;
            print(planIsActive0);
          });
        }
      }
      else if (topic.split('/')[2] == "pump1"){
        if (topic.split('/')[3] == 'data') {
          setState(() {
            activeThreshold1 = message;
          });
        }
        else if (topic.split('/')[3] == 'planIsActive'){
          setState(() {
            print('PORCODIO');
            planIsActive1 = message;
          });
        }
      }
    });
  }

  Future<void> _loadDeviceId() async {
    deviceID = await _storage.read(key: 'deviceId') ?? '';
  }

  Future<void> _saveIndexStyle(int indexStyle, int indexData) async {
    await _storage.write(key: (indexData == 0)? 'gaugeStyle0':'gaugeStyle1', value: indexStyle.toString());
  }

  Future<void> _loadIndexStyle() async {
    gaugeStyleIndex0 = int.parse(await _storage.read(key: 'gaugeStyle0') ?? '0');
    gaugeStyleIndex1 = int.parse(await _storage.read(key: 'gaugeStyle1') ?? '0');
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        // The Bottom margin is provided to align the popup above the system navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }

  Future<void> _navigateAndDisplaySelection(BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    List<double> randomDoubles = [];
    for (int i = 0; i < 6; i++){
      randomDoubles.add((Random().nextDouble()*100).floorToDouble());
    }
    if (_currentIndexData) {
      gaugeStyleIndex1 = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GaugeStylePicker(randVals: randomDoubles,)),
      ) ?? gaugeStyleIndex1;

      _saveIndexStyle(gaugeStyleIndex1, 1);

      // When a BuildContext is used from a StatefulWidget, the mounted property
      // must be checked after an asynchronous gap.
      if (!context.mounted) return;

      // After the Selection Screen returns a result, hide any previous snackbars
      // and show the new result.
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('The style was updated')));
    }
    else{
      gaugeStyleIndex0 = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GaugeStylePicker(randVals: randomDoubles,)),
      ) ?? gaugeStyleIndex0;

      _saveIndexStyle(gaugeStyleIndex0, 0);

      // When a BuildContext is used from a StatefulWidget, the mounted property
      // must be checked after an asynchronous gap.
      if (!context.mounted) return;

      // After the Selection Screen returns a result, hide any previous snackbars
      // and show the new result.
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('The style was updated')));
    }
  }

  Widget _getGauge(int indexStyle, int indexData, {bool isRadialGauge = true}) {
    if (isRadialGauge) {
      _loadIndexStyle();
      return _getRadialGauge(indexStyle, indexData);
    } else {
      return _getLinearGauge();
    }
  }

  Widget _getRadialGauge(indexStyle, indexData) {
    return SfRadialGauge(
      title: GaugeTitle(
        text: (indexData == 0)? 'Plant 1':'Plant 2',
        textStyle:
        const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Colors.white)),
      animationDuration: 3500,
      enableLoadingAnimation: true,
      axes: <RadialAxis>[
        [
          RadialAxis(
            showLastLabel: true,
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                angle: 0, positionFactor: 0,
                widget: Text(
                  '${(indexData == 0)? status0:status1}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.height/30,
                    color: Colors.white
                  ),
                )
              ),
            ],
            interval: 10,
            axisLabelStyle: GaugeTextStyle(color: Colors.grey),
            axisLineStyle: AxisLineStyle(
                gradient: SweepGradient(colors: <Color>[
                  Colors.red,
                  Colors.green,
                ], stops: <double>[
                  0.25,
                  0.75,
                ])),
            pointers: <GaugePointer>[
              /*NeedlePointer(
              value: (_currentIndexData)? double.parse('${status1}.0') : double.parse('${status0}.0'),
              knobStyle: KnobStyle(knobRadius: 0.1),
              needleStartWidth: 5,
              needleEndWidth: 7,
              lengthUnit: GaugeSizeUnit.factor,
              needleLength: 0.8,
              needleColor: Colors.grey,
            ),*/
              MarkerPointer(
                  value: double.parse('${(indexData == 0)? status0:status1}.0'),
                  markerHeight: 10, markerWidth: 10, elevation: 4
              ),
            ],
          ),

          RadialAxis(
            showLastLabel: true,
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                  angle: 90, positionFactor: 0.75,
                  widget: Text('${(indexData == 0)? status0:status1}%', style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.height/30, color: Colors.white),)),
            ],
            interval: 10,
            axisLabelStyle: GaugeTextStyle(color: Colors.grey),
            axisLineStyle: AxisLineStyle(
                gradient: SweepGradient(colors: <Color>[
                  Colors.red,
                  Colors.green,
                ], stops: <double>[
                  0.25,
                  0.75,
                ])),
            pointers: <GaugePointer>[
              NeedlePointer(
                value: double.parse('${(indexData == 0)? status0:status1}.0'),
                knobStyle: KnobStyle(knobRadius: 0.1),
                needleStartWidth: 5,
                needleEndWidth: 7,
                animationType: AnimationType.easeOutBack,
                enableAnimation: true,
                animationDuration: 1200,
                lengthUnit: GaugeSizeUnit.factor,
                needleLength: 0.8,
                needleColor: Colors.grey,
              ),
            ],
          ),

          RadialAxis(
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                  angle: 0, positionFactor: 0,
                  widget: Text('${(indexData == 0)? status0:status1}%', style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.height/30, color: Colors.white),)),
            ],
            interval: 10,
            axisLabelStyle: GaugeTextStyle(color: Colors.grey),
            axisLineStyle: AxisLineStyle(
              color: Colors.purpleAccent,
            ),
            pointers: <GaugePointer>[
                RangePointer(value: double.parse('${(indexData == 0)? status0:status1}.0'), dashArray: <double>[3, 3], color: Colors.black),
            ]
          ),
          RadialAxis(
              minimum: 0,
              maximum: 100,
              minorTicksPerInterval: 9,
              showLastLabel: true,
              showAxisLine: false,
              labelOffset: 8,
              ranges: <GaugeRange>[
                GaugeRange(
                    startValue: 66,
                    endValue: 100,
                    startWidth: 0.265,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.265,
                    color: const Color.fromRGBO(123, 199, 34, 0.75)),
                GaugeRange(
                    startValue: 33,
                    endValue: 66,
                    startWidth: 0.265,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.265,
                    color: const Color.fromRGBO(238, 193, 34, 0.75)),
                GaugeRange(
                    startValue: 0,
                    endValue: 33,
                    startWidth: 0.265,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.265,
                    color: const Color.fromRGBO(238, 79, 34, 0.65)),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    angle: 90,
                    positionFactor: 0.35,
                    widget: Text(
                        'Moisture',
                        style:
                        TextStyle(color: Color(0xFFF8B195), fontSize: 10))),
                GaugeAnnotation(
                  angle: 90,
                  positionFactor: 0.75,
                  widget: Text(
                    '${(indexData == 0)? status0:status1}%',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
              pointers: <GaugePointer>[
                NeedlePointer(
                  value: double.parse('${(indexData == 0)? status0:status1}.0'),
                  needleStartWidth: 0,
                  needleEndWidth: 5,
                  animationType: AnimationType.easeOutBack,
                  enableAnimation: true,
                  animationDuration: 1200,
                  knobStyle: KnobStyle(
                      knobRadius: 0.09,
                      borderColor: const Color(0xFFF8B195),
                      color: Color(0xdd222222),
                      borderWidth: 0.035),
                  tailStyle: TailStyle(
                      color: const Color(0xFFF8B195),
                      width: 4,
                      length: 0.15),
                  needleColor: const Color(0xFFF8B195),
                )
              ],
              axisLabelStyle: GaugeTextStyle(fontSize: 12, color: Colors.grey),
              majorTickStyle: const MajorTickStyle(
                  length: 0.25, lengthUnit: GaugeSizeUnit.factor),
              minorTickStyle: const MinorTickStyle(
                  length: 0.13, lengthUnit: GaugeSizeUnit.factor, thickness: 1)),
          RadialAxis(
              startAngle: 180,
              endAngle: 360,
              interval: 10,
              canScaleToFit: true,
              showLastLabel: true,
              radiusFactor: 1.2,
              minorTickStyle: const MinorTickStyle(
                  length: 0.05, lengthUnit: GaugeSizeUnit.factor),
              majorTickStyle: const MajorTickStyle(
                  length: 0.1, lengthUnit: GaugeSizeUnit.factor),
              minorTicksPerInterval: 5,
              pointers: <GaugePointer>[
                NeedlePointer(
                    value: double.parse((indexData == 0)? '$status0.0':'$status1.0'),
                    needleEndWidth: 3,
                    needleLength: 0.8,
                    animationType: AnimationType.easeOutBack,
                    enableAnimation: true,
                    animationDuration: 1200,
                    knobStyle: KnobStyle(
                      knobRadius: 8,
                      sizeUnit: GaugeSizeUnit.logicalPixel,
                    ),
                    tailStyle: TailStyle(
                        width: 3,
                        lengthUnit: GaugeSizeUnit.logicalPixel,
                        length: 20))
              ],
              axisLabelStyle: const GaugeTextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
              axisLineStyle:
              const AxisLineStyle(thickness: 3, color: Color(0xFF00A8B5))),
          RadialAxis(
              showAxisLine: false,
              showLabels: false,
              showTicks: false,
              startAngle: 180,
              endAngle: 360,
              maximum: 100,
              canScaleToFit: true,
              radiusFactor: 1.2,
              pointers: <GaugePointer>[
                NeedlePointer(
                    needleEndWidth: 5,
                    needleLength: 0.7,
                    animationType: AnimationType.easeOutBack,
                    enableAnimation: true,
                    animationDuration: 1200,
                    value: double.parse((indexData == 0)? '$status0.0':'$status1.0'),
                    knobStyle: KnobStyle(knobRadius: 0)),
              ],
              ranges: <GaugeRange>[
                GaugeRange(
                    startValue: 0,
                    endValue: 16,
                    startWidth: 0.45,
                    endWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: const Color(0xFFDD3800)),
                GaugeRange(
                    startValue: 16.5,
                    endValue: 33,
                    startWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.45,
                    color: const Color(0xFFFF4100)),
                GaugeRange(
                    startValue: 33.5,
                    endValue: 50,
                    startWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.45,
                    color: const Color(0xFFFFBA00)),
                GaugeRange(
                    startValue: 50.5,
                    endValue: 66,
                    startWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.45,
                    color: const Color(0xFFFFDF10)),
                GaugeRange(
                    startValue: 66.5,
                    endValue: 82.5,
                    sizeUnit: GaugeSizeUnit.factor,
                    startWidth: 0.45,
                    endWidth: 0.45,
                    color: const Color(0xFF8BE724)),
                GaugeRange(
                    startValue: 83,
                    endValue: 100,
                    startWidth: 0.45,
                    endWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: const Color(0xFF64BE00)),
              ]
          ),
        ][indexStyle],
      ],
    );
  }

  Widget _getLinearGauge() {
    return Container(
      margin: EdgeInsets.all(10),
      child: SfLinearGauge(
          minimum: 0.0,
          maximum: 100.0,
          orientation: LinearGaugeOrientation.horizontal,
          majorTickStyle: LinearTickStyle(length: 20),
          axisLabelStyle: TextStyle(fontSize: 12.0, color: Colors.black),
          axisTrackStyle: LinearAxisTrackStyle(
              color: Colors.cyan,
              edgeStyle: LinearEdgeStyle.bothFlat,
              thickness: 15.0,
              borderColor: Colors.grey)),
    );
  }

  void _updateIndexData(newIndex){
    bool newBoolIndex = (newIndex == 0)? false:true;
    setState(() {
      _currentIndexData = newBoolIndex;
    });
  }

  List<int> getTimeNow(){
    final now = DateTime.now();
    var hourNow = now.hour;
    var minuteNow = now.minute;
    return [hourNow, minuteNow, 0];
  }

  void _updateIndex(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
      modeBar = [
        Offset(0,0),
        Offset(1,0).scale(1.23, 0),
        Offset(2,0).scale(1.165, 0)
      ][newIndex];
      modeColor = [
        Color(0xffD32F2F),
        Colors.blue,
        Colors.yellow,
      ][newIndex];
    });
  }

  void sendManualCommand(bool pump, String command) {
    if (deviceID.isNotEmpty) {
      mqttService.publishMessage('esp32/$deviceID/pump${(pump)?1:0}/control', command);
    }
  }

  void sendAutoCommand(bool pump, String time) {
    if (deviceID.isNotEmpty) {
      mqttService.publishMessage('esp32/$deviceID/pump${(pump)?1:0}/control', time);
    }
  }

  void setThreshold(bool pump, String threshold){
    if (deviceID.isNotEmpty){
      mqttService.publishMessage('esp32/$deviceID/sensor${(pump)?1:0}/control', threshold);
    }
  }

  void planCommand(bool pump, String timeout, String interval, int dt) {
    if (deviceID.isNotEmpty) {
      String message = '$timeout&$interval&$dt';
      mqttService.publishMessage('esp32/$deviceID/pump${(pump)?1:0}/plan', message);
    }
  }

  void stopPlan(bool pump){
    if (deviceID.isNotEmpty) {
      mqttService.publishMessage('esp32/$deviceID/pump${pump?1:0}/plan', 'stop');
    }
  }

  double findTextWidth(String text, double fontSize){
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, color: Colors.white),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    return tp.width;
  }


  @override
  Widget build(BuildContext context) {
    List<Widget> panelsData = [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              _navigateAndDisplaySelection(context);
            },
            child: SizedBox(
              height: MediaQuery.of(context).size.height/4.5,
              width: MediaQuery.of(context).size.height/4.5,
              child: _getGauge(gaugeStyleIndex0, 0),
            ),
          ),
          /*Text(
          (status0.isNotEmpty) ? '$status0%' : '0%',
          style: TextStyle(fontSize: MediaQuery.of(context).size.height/10, color: Colors.grey),
          ),*/
        ]
      ),
      Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                _navigateAndDisplaySelection(context);
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height/4.5,
                width: MediaQuery.of(context).size.height/4.5,
                child: _getGauge(gaugeStyleIndex1, 1),
              ),
            )
            /*Text(
          (status0.isNotEmpty) ? '$status0%' : '0%',
          style: TextStyle(fontSize: MediaQuery.of(context).size.height/10, color: Colors.grey),
          ),*/
          ]
      ),
    ];
    final List<Widget> panels = [
      Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                NumberPicker(
                  value: _value,
                  minValue: 0,
                  maxValue: 100,
                  haptics: true,
                  itemHeight: MediaQuery.of(context).size.height/25,
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.height/28,
                  ),
                  textStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: MediaQuery.of(context).size.height/60,
                  ),
                  onChanged: (value) => setState(() {
                    _value = value;
                    autoWateringTime = _value.toString();
                  }),
                ),
                ElevatedButton(
                  onPressed: () => sendAutoCommand(_currentIndexData, autoWateringTime),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red, shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height/25),
                  ),
                    padding: EdgeInsets.all(MediaQuery.of(context).size.height/60), // Text color
                  ),
                  child: Text(
                    'Watering $autoWateringTime sec',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: MediaQuery.of(context).size.height/40,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Center the Column vertically
              children: [
                CupertinoSwitch(
                  // This bool value toggles the switch.
                  value: switchValue,
                  activeColor: CupertinoColors.black,
                  thumbColor: CupertinoColors.systemRed,
                  onChanged: (bool? value) {
                    // This is called when the user toggles the switch.
                    setState(() {
                      switchValue = value ?? false;
                      String msg = switchValue? 'start':'stop';
                      sendManualCommand(_currentIndexData, msg);
                    });
                  },
                ),
                HoldTimeoutDetector(
                  onTimeout: () {},
                  onTimerInitiated: () => sendManualCommand(_currentIndexData, 'start'),
                  onCancel: () => sendManualCommand(_currentIndexData, 'stop'),
                  holdTimeout: Duration(milliseconds: 100),
                  enableHapticFeedback: true,
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Color(0xffD32F2F), shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height/25),
                    ), // Make the button round
                      padding: EdgeInsets.all(MediaQuery.of(context).size.height/60), // Text color
                    ),
                    child: Text(
                      'Hold',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: MediaQuery.of(context).size.height/40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
      ),

      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Center the Column vertically
          children: [
            Text(
              'Current Threshold Value: ${_currentIndexData? activeThreshold1:activeThreshold0}%',
              style: TextStyle(
                color: Colors.blue,
                fontSize: MediaQuery.of(context).size.height/50,
              ),
            ),
            NumberPicker(
              value: (_currentIndexData)? _threshold1 : _threshold0,
              minValue: 0,
              maxValue: 100,
              haptics: true,
              itemHeight: MediaQuery.of(context).size.height/20,
              selectedTextStyle: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.height/25,
              ),
              textStyle: TextStyle(
                color: Colors.grey,
                fontSize: MediaQuery.of(context).size.height/40,
                ),
              onChanged: (value) => setState(() {
                if (_currentIndexData){
                  _threshold1 = value;
                  threshold1 = _threshold1.toString();
                }
                else {
                  _threshold0 = value;
                  threshold0 = _threshold0.toString();
                }
              }),
            ),
            ElevatedButton(
              onPressed: () => setThreshold(_currentIndexData, (_currentIndexData)? threshold1 : threshold0),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue, shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height/20),
              ),
                padding: EdgeInsets.all(MediaQuery.of(context).size.height/60), // Text color
              ),
              child: Text(
                'Set Threshold to ${(_currentIndexData)? threshold1 : threshold0}%',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: MediaQuery.of(context).size.height/50,
                ),
              ),
            ),
          ],
        ),
      ),
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:[
                Text(
                  'Select Time and Frequency:',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: MediaQuery.of(context).size.height/50,
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.height/50,
                  height: MediaQuery.of(context).size.height/50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_currentIndexData)? ((planIsActive1 == 'true')? Colors.green:Colors.red) : ((planIsActive0 == 'true')? Colors.green:Colors.red),
                  ),
                )
              ],
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _TimerPickerItem(
                        children: <Widget>[
                          // const Text('Timer'),
                          CupertinoButton(
                            // Display a CupertinoTimerPicker with hour/minute mode.
                            onPressed: () => _showDialog(
                              CupertinoTimerPicker(
                                mode: CupertinoTimerPickerMode.hm,
                                initialTimerDuration: duration,
                                // This is called when the user changes the timer's
                                // duration.
                                onTimerDurationChanged: (Duration newDuration) {
                                  setState(() => duration = newDuration);
                                },
                              ),
                            ),
                            // In this example, the timer's value is formatted manually.
                            // You can use the intl package to format the value based on
                            // the user's locale settings.
                            child: Text(
                              '${(duration.inHours ~/10 == 0)? '0${duration.inHours}' : '${duration.inHours}'} : ${(duration.inMinutes.remainder(60) ~/ 10 == 0)? '0${duration.inMinutes.remainder(60)}' : '${duration.inMinutes.remainder(60)}'}',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.height/20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  NumberPicker(
                    value: interval,
                    minValue: 0,
                    maxValue: 365,
                    haptics: true,
                    itemWidth: MediaQuery.of(context).size.width/10,
                    itemHeight: MediaQuery.of(context).size.height/30,
                    selectedTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.height/35,
                    ),
                    textStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: MediaQuery.of(context).size.height/45,
                    ),
                    onChanged: (value) => setState(() {
                      interval = value;
                    }),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    // Display a CupertinoPicker with list of fruits.
                    onPressed: () => _showDialog(
                      CupertinoPicker(
                        magnification: 1.22,
                        squeeze: 1.2,
                        useMagnifier: true,
                        itemExtent: 32.0,
                        // This sets the initial item.
                        scrollController: FixedExtentScrollController(
                          initialItem: _selectedTimeUnit,
                        ),
                        // This is called when selected item is changed.
                        onSelectedItemChanged: (int selectedItem) {
                          setState(() {
                            _selectedTimeUnit = selectedItem;
                          });
                        },
                        children:
                        List<Widget>.generate(timeUnits.length, (int index) {
                          return Center(child: Text(timeUnits[index]));
                        }),
                      ),
                    ),
                    // This displays the selected fruit name.
                    child: Text(
                      timeUnits[_selectedTimeUnit],
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height/40,
                          color: Colors.white
                      ),
                    ),
                  ),
                ],
              )
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () => setState(() {
                    final newValue = _currentPlan - 1;
                    _currentPlan = newValue.clamp(0, 100);
                  }),
                ),
                NumberPicker(
                  value: _currentPlan,
                  minValue: 0,
                  maxValue: 59,
                  step: 1,
                  itemHeight: MediaQuery.of(context).size.height/15,
                  itemWidth: MediaQuery.of(context).size.width/8,
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.height/40,
                  ),
                  textStyle: TextStyle(
                    color: Colors.transparent,
                    fontSize: MediaQuery.of(context).size.height/50,
                  ),
                  axis: Axis.horizontal,
                  onChanged: (value) =>
                      setState(() => _currentPlan = value),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height/30),
                    border: Border.all(color: Colors.black26),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => setState(() {
                    final newValue = _currentPlan + 1;
                    _currentPlan = newValue.clamp(0, 100);
                  }),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    stopPlan(_currentIndexData);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red, shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height/20),
                  ),
                    padding: EdgeInsets.all(MediaQuery.of(context).size.height/70), // Text color
                  ),
                  child: Text(
                    'Stop All',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: MediaQuery.of(context).size.height/50,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    String timeout = '${duration.inHours}:${duration.inMinutes.remainder(60)}';
                    String timeFrequency = interval.toString() + timeUnits[_selectedTimeUnit].substring(0,1);
                    planCommand(_currentIndexData, timeout, timeFrequency, _currentPlan);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.yellow, shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height/20),
                  ),
                    padding: EdgeInsets.all(MediaQuery.of(context).size.height/70), // Text color
                  ),
                  child: Text(
                    'Plan Watering ${_currentPlan.toString()} sec',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: MediaQuery.of(context).size.height/50,
                    ),
                  ),
                ),
              ],
            )
          ],
        )
      ),
    ];

    Widget _buildListItem(BuildContext context, int index) {
      return Container(
        width: MediaQuery.of(context).size.width - 20,
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xdd222222),
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height/15),
              boxShadow: [
                BoxShadow(
                  color: Color(0x4c000000),
                  spreadRadius: 4,
                  blurRadius: 10,
                  offset: Offset(2, 4), // changes position of shadow
                ),
              ],
            ),
            child: panels[index],
          ),
        ),
      );
    }
    Widget _buildListItemData(BuildContext context, int index) {
      return Container(
        width: MediaQuery.of(context).size.width - 20,
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xdd222222),
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height/15),
              boxShadow: [
                BoxShadow(
                  color: Color(0x4c000000),
                  spreadRadius: 4,
                  blurRadius: 10,
                  offset: Offset(2, 4), // changes position of shadow
                ),
              ],
            ),
            child: panelsData[index],
          ),
        ),
      );
    }



    return Scaffold(
      backgroundColor: Color(0xff121212),
      body: Container(
        /* decoration: BoxDecoration(
          /*gradient: RadialGradient(
            colors: [Color(0xff870000), Color(0xff190a05)],
            stops: [0, 1],
            center: Alignment(0.0, -0.5),
          ),*/
          color: Color(0xff121212)
        ), */
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height/20,
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height/20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () async {
                              _loadDeviceId();
                              _loadIndexStyle();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: Duration(seconds: 5),
                                  content: Text('Style and ID refreshed'),
                                ),
                              );
                            },
                            style: ButtonStyle(
                              splashFactory: NoSplash.splashFactory,
                              overlayColor: WidgetStateProperty.all(Colors.transparent),
                            ),
                            icon: const Icon(Icons.autorenew_rounded),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width/80, vertical: MediaQuery.of(context).size.height/200),
                              shadowColor: Colors.white,
                              splashFactory: NoSplash.splashFactory,
                              overlayColor: Colors.transparent,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DeviceIdPage()),
                              );
                              await _loadDeviceId();
                              await _setupMqttConnection();
                            },
                            child: Text(
                              'ID: $deviceID',
                              style: TextStyle(fontSize: MediaQuery.of(context).size.height/40, color: Colors.black),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.height/50,
                            height: MediaQuery.of(context).size.height/50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (connectedClient)? Colors.green:Colors.red,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Stack(
                  alignment: Alignment(0,0),
                  children: [
                    Positioned(
                      left: MediaQuery.of(context).size.width/10,
                      child: AnimatedSlide(
                        offset: modeBar,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeInOut,
                        child: Container(
                          width: MediaQuery.of(context).size.width/4,
                          height: MediaQuery.of(context).size.height/28,
                          decoration: BoxDecoration(
                            color: modeColor,
                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width/20),
                          ),
                        ),
                      )
                    ),
                    // Row containing the TextButtons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {},// => _updateIndex(0),
                          style: ButtonStyle(
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: Text(
                            'Manual',
                            style: TextStyle(
                              color: (_currentIndex == 0) ? Colors.black : Color(0xffD32F2F),
                              fontSize: MediaQuery.of(context).size.height/40,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {}, //=> _updateIndex(1),
                          style: ButtonStyle(
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: Text(
                            'Auto',
                            style: TextStyle(
                              color: (_currentIndex == 1) ? Colors.black : Colors.blue,
                              fontSize: MediaQuery.of(context).size.height/40,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: (){}, // => _updateIndex(2),
                          style: ButtonStyle(
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: Text(
                            'Plan',
                            style: TextStyle(
                              color: (_currentIndex == 2) ? Colors.black : Colors.yellow,
                              fontSize: MediaQuery.of(context).size.height/40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height/80,
                ),
                Container(
                  height: MediaQuery.of(context).size.height/4,
                  child: Column( // this column is completely useless but `Expanded` ideally shouldn't ly in a `Container`
                    children: [
                      Expanded(
                        child: ScrollSnapList(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          onItemFocus: _updateIndexData,
                          itemSize: MediaQuery.of(context).size.width,
                          itemBuilder: _buildListItemData,
                          itemCount: panelsData.length,
                          key: sslKeyData,
                          scrollDirection: Axis.horizontal,
                          scrollPhysics: PageScrollPhysics(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            /*Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 4,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                itemCount: panelsData.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndexData = index as bool;
                      });
                      _centerSelectedItem(); // Auto center the selected item
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 4,
                        decoration: BoxDecoration(
                          color: Color(0xdd222222),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x4c000000),
                              spreadRadius: 4,
                              blurRadius: 10,
                              offset: Offset(2, 4), // changes position of shadow
                            ),
                          ],
                        ),
                        child: panelsData[index],
                      ),
                    ),
                  );
                },
              ),
            ),*/
            /*Positioned(
              left: 20,
              right: 20,
              child: AnimatedSlide(
                offset: offsetData[0],
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xdd222222),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4c000000),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(2, 4), // changes position of shadow
                      ),
                    ],
                  ),
                  child: panelsData[0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              child: AnimatedSlide(
                offset: offsetData[1],
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xdd222222),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4c000000),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(2, 4), // changes position of shadow
                      ),
                    ],
                  ),
                  child: panelsData[1],
                ),
              ),
            ),*/
            Container(
              height: MediaQuery.of(context).size.height/2.75,
              child: Column(
                children: [
                  Expanded(
                    child: ScrollSnapList(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      onItemFocus: _updateIndex,
                      itemSize: MediaQuery.of(context).size.width,
                      itemBuilder: _buildListItem,
                      itemCount: panels.length,
                      key: sslKey,
                      scrollDirection: Axis.horizontal,
                      scrollPhysics: PageScrollPhysics(),
                    ),
                  ),
                ],
              ),
            ),
            /*Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 4,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                itemCount: panels.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = index;
                      });
                      _centerSelectedItem(); // Auto center the selected item
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 4,
                        decoration: BoxDecoration(
                          color: Color(0xdd222222),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x4c000000),
                              spreadRadius: 4,
                              blurRadius: 10,
                              offset: Offset(2, 4), // changes position of shadow
                            ),
                          ],
                        ),
                        child: panels[index],
                      ),
                    ),
                  );
                },
              ),
            ),*/
            /*Positioned(
              left: 20,
              right: 20,
              child: AnimatedSlide(
                offset: offset[0],
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xdd222222),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4c000000),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(2, 4), // changes position of shadow
                      ),
                    ],
                  ),
                  child: panels[0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              child: AnimatedSlide(
                offset: offset[1],
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xdd222222),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4c000000),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(2, 4), // changes position of shadow
                      ),
                    ],
                  ),
                  child: panels[1],
                )
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              child: AnimatedSlide(
                offset: offset[2],
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xdd222222),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4c000000),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(2, 4), // changes position of shadow
                      ),
                    ],
                  ),
                  child: panels[2],
                )
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}



// const textStyle = TextStyle(fontSize: 20, color: Colors.black);

class _TimerPickerItem extends StatelessWidget {
  const _TimerPickerItem({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.inactiveGray,
            width: 0.0,
          ),
          bottom: BorderSide(
            color: CupertinoColors.inactiveGray,
            width: 0.0,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      ),
    );
  }
}


class GaugeStylePicker extends StatelessWidget {
  const GaugeStylePicker({super.key, required this.randVals});

  final List<double> randVals;

  Widget _getGauge(int index, {bool isRadialGauge = true}) {
    if (isRadialGauge) {
      return _getRadialGauge(index);
    } else {
      return _getLinearGauge();
    }
  }

  Widget _getRadialGauge(index) {
    return SfRadialGauge(
      /*title: GaugeTitle(
          text: 'Example',
          textStyle:
          const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white)),*/
      axes: <RadialAxis>[
        [
          RadialAxis(
              showLastLabel: true,
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    angle: 0, positionFactor: 0,
                    widget: Text('${randVals[0].toInt()}%', style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 30.0, color: Colors.white),))
              ],
              interval: 10,
              axisLabelStyle: GaugeTextStyle(color: Colors.grey),
              axisLineStyle: AxisLineStyle(
                  gradient: SweepGradient(colors: <Color>[
                    Colors.red,
                    Colors.green,
                  ], stops: <double>[
                    0.25,
                    0.75,
                  ])),
              pointers: <GaugePointer>[
                /*NeedlePointer(
                value: (_currentIndexData)? double.parse('${status1}.0') : double.parse('${status0}.0'),
                knobStyle: KnobStyle(knobRadius: 0.1),
                needleStartWidth: 5,
                needleEndWidth: 7,
                lengthUnit: GaugeSizeUnit.factor,
                needleLength: 0.8,
                needleColor: Colors.grey,
              ),*/
                MarkerPointer(
                    value: randVals[0],
                    markerHeight: 10, markerWidth: 10, elevation: 4
                )
              ]
          ),

          RadialAxis(
            showLastLabel: true,
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                  angle: 90, positionFactor: 0.75,
                  widget: Text('${randVals[1].toInt()}%', style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white),))
            ],
            interval: 10,
            axisLabelStyle: GaugeTextStyle(color: Colors.grey),
            axisLineStyle: AxisLineStyle(
                gradient: SweepGradient(colors: <Color>[
                  Colors.red,
                  Colors.green,
                ], stops: <double>[
                  0.25,
                  0.75,
                ])),
            pointers: <GaugePointer>[
              NeedlePointer(
                value: randVals[1],
                animationType: AnimationType.bounceOut,
                enableAnimation: true,
                animationDuration: 1200,
                knobStyle: KnobStyle(knobRadius: 0.1),
                needleStartWidth: 5,
                needleEndWidth: 7,
                lengthUnit: GaugeSizeUnit.factor,
                needleLength: 0.8,
                needleColor: Colors.grey,
              ),
            ],
          ),
          RadialAxis(
              showLastLabel: true,
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    angle: 0, positionFactor: 0,
                    widget: Text('${randVals[2].toInt()}%', style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 30.0, color: Colors.white),))
              ],
              interval: 10,
              axisLabelStyle: GaugeTextStyle(color: Colors.grey),
              axisLineStyle: AxisLineStyle(
                color: Colors.purpleAccent,
              ),
              pointers: <GaugePointer>[
                RangePointer(value: randVals[2], dashArray: <double>[3, 3], color: Colors.black)
              ]
          ),
          RadialAxis(
              minimum: 0,
              maximum: 100,
              minorTicksPerInterval: 9,
              showLastLabel: true,
              showAxisLine: false,
              labelOffset: 8,
              ranges: <GaugeRange>[
                GaugeRange(
                    startValue: 66,
                    endValue: 100,
                    startWidth: 0.265,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.265,
                    color: const Color.fromRGBO(123, 199, 34, 0.75)),
                GaugeRange(
                    startValue: 33,
                    endValue: 66,
                    startWidth: 0.265,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.265,
                    color: const Color.fromRGBO(238, 193, 34, 0.75)),
                GaugeRange(
                    startValue: 0,
                    endValue: 33,
                    startWidth: 0.265,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.265,
                    color: const Color.fromRGBO(238, 79, 34, 0.65)),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    angle: 90,
                    positionFactor: 0.35,
                    widget: Text('Moisture',
                        style:
                        TextStyle(color: Color(0xFFF8B195), fontSize: 10))),
                GaugeAnnotation(
                  angle: 90,
                  positionFactor: 0.75,
                  widget: Text(
                    '${randVals[3].toInt()}%',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
              pointers: <GaugePointer>[
                NeedlePointer(
                  value: randVals[3],
                  needleStartWidth: 0,
                  needleEndWidth: 5,
                  animationType: AnimationType.easeOutBack,
                  enableAnimation: true,
                  animationDuration: 1200,
                  knobStyle: KnobStyle(
                      knobRadius: 0.09,
                      borderColor: const Color(0xFFF8B195),
                      color: Color(0xdd222222),
                      borderWidth: 0.035),
                  tailStyle: TailStyle(
                      color: const Color(0xFFF8B195),
                      width: 4,
                      length: 0.15),
                  needleColor: const Color(0xFFF8B195),
                )
              ],
              axisLabelStyle: GaugeTextStyle(fontSize: 12, color: Colors.grey),
              majorTickStyle: const MajorTickStyle(
                  length: 0.25, lengthUnit: GaugeSizeUnit.factor),
              minorTickStyle: const MinorTickStyle(
                  length: 0.13, lengthUnit: GaugeSizeUnit.factor, thickness: 1)),
          RadialAxis(
              startAngle: 180,
              endAngle: 360,
              interval: 10,
              canScaleToFit: true,
              showLastLabel: true,
              minorTickStyle: const MinorTickStyle(
                  length: 0.05, lengthUnit: GaugeSizeUnit.factor),
              majorTickStyle: const MajorTickStyle(
                  length: 0.1, lengthUnit: GaugeSizeUnit.factor),
              minorTicksPerInterval: 5,
              pointers: <GaugePointer>[
                NeedlePointer(
                    value: randVals[4],
                    needleEndWidth: 3,
                    needleLength: 0.8,
                    animationType: AnimationType.slowMiddle,
                    enableAnimation: true,
                    animationDuration: 1200,
                    knobStyle: KnobStyle(
                      knobRadius: 8,
                      sizeUnit: GaugeSizeUnit.logicalPixel,
                    ),
                    tailStyle: TailStyle(
                        width: 3,
                        lengthUnit: GaugeSizeUnit.logicalPixel,
                        length: 20))
              ],
              axisLabelStyle: const GaugeTextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
              axisLineStyle:
              const AxisLineStyle(thickness: 3, color: Color(0xFF00A8B5))),
          RadialAxis(
              showAxisLine: false,
              showLabels: false,
              showTicks: false,
              startAngle: 180,
              endAngle: 360,
              maximum: 120,
              canScaleToFit: true,
              radiusFactor: 1,
              pointers: <GaugePointer>[
                NeedlePointer(
                    needleEndWidth: 5,
                    needleLength: 0.7,
                    value: randVals[5],
                    animationType: AnimationType.elasticOut,
                    enableAnimation: true,
                    animationDuration: 1200,
                    knobStyle: KnobStyle(knobRadius: 0)),
              ],
              ranges: <GaugeRange>[
                GaugeRange(
                    startValue: 0,
                    endValue: 20,
                    startWidth: 0.45,
                    endWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: const Color(0xFFDD3800)),
                GaugeRange(
                    startValue: 20.5,
                    endValue: 40,
                    startWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.45,
                    color: const Color(0xFFFF4100)),
                GaugeRange(
                    startValue: 40.5,
                    endValue: 60,
                    startWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.45,
                    color: const Color(0xFFFFBA00)),
                GaugeRange(
                    startValue: 60.5,
                    endValue: 80,
                    startWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    endWidth: 0.45,
                    color: const Color(0xFFFFDF10)),
                GaugeRange(
                    startValue: 80.5,
                    endValue: 100,
                    sizeUnit: GaugeSizeUnit.factor,
                    startWidth: 0.45,
                    endWidth: 0.45,
                    color: const Color(0xFF8BE724)),
                GaugeRange(
                    startValue: 100.5,
                    endValue: 120,
                    startWidth: 0.45,
                    endWidth: 0.45,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: const Color(0xFF64BE00)),
              ]
          ),
        ][index],
      ],
    );
  }
  Widget _getLinearGauge() {
    return Container(
      margin: EdgeInsets.all(10),
      child: SfLinearGauge(
          minimum: 0.0,
          maximum: 100.0,
          orientation: LinearGaugeOrientation.horizontal,
          majorTickStyle: LinearTickStyle(length: 20),
          axisLabelStyle: TextStyle(fontSize: 12.0, color: Colors.black),
          axisTrackStyle: LinearAxisTrackStyle(
              color: Colors.cyan,
              edgeStyle: LinearEdgeStyle.bothFlat,
              thickness: 15.0,
              borderColor: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        title: const Text('Pick a Style'),
        foregroundColor: Colors.white,
        backgroundColor: Color(0xdd222222),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 50, horizontal: 20),
          child: GridView.count(
            mainAxisSpacing: MediaQuery.of(context).size.height/40,
            crossAxisSpacing: MediaQuery.of(context).size.width/40,
            crossAxisCount: 2,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, 0);
                },
                child: SizedBox(
                  child: _getGauge(0),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, 1);
                },
                child: SizedBox(
                  child: _getGauge(1),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, 2);
                },
                child: SizedBox(
                  child: _getGauge(2),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, 3);
                },
                child: SizedBox(
                  child: _getGauge(3),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, 4);
                },
                child: SizedBox(
                  child: _getGauge(4),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, 5);
                },
                child: SizedBox(
                  child: _getGauge(5),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }
}