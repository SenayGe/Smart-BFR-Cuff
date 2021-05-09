import 'dart:async';
import 'dart:convert';
import 'package:bitalino/bitalino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:smart_cuff/Tabs/EmgPage.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:smart_cuff/HelperClasses/Utilities.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import '../Charts/chart.dart';

class DashBoard extends StatefulWidget {
  String lop;
   DashBoard( {this.lop});
  @override
  _DashBoardState createState() => _DashBoardState();

}

class _DashBoardState extends State<DashBoard>
    with AutomaticKeepAliveClientMixin<DashBoard> {

  _DashBoardState({this.lop});
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BITalinoController bitalinoController;
  bool isBitalinoConnected=false;
  bool isSessionStarted = false;
  bool isAcquisitionStarted = false;
  bool isPressureValveClosed = false;
  int cuffPressure = 0;
  double emg = 0;
  String hrsStr = '00';
  String minStr = '00';
  String secStr = '00';
  int timeElapsed = 0;
  //final String bitalinoMacAddress = "98:D3:51:FD:9D:72";
  final String bitalinoMacAddress = "98:D3:21:FC:8B:72";
  final String arduinoMacAddress ="C4:4F:33:69:C4:87";
  //final String arduinoMacAddress = "7C:9E:BD:E3:D0:7E";
  BluetoothConnection connection;
  StreamSubscription<int> timerStreamSubscription;
  Stream<int> timeStream;
  int lopPercentage = 60;
  String lop;
  List<SensorValue> data = [];
  List<SensorValue> data2 = [];
  DateTime previousTime;


  final textFieldController = TextEditingController();

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
  @override
  Future<void> initState() {
    // TODO: implement initState
    super.initState();
    lop = widget.lop;
    initPlatformState();

    Future.delayed(const Duration(seconds: 1), (){
      setupBitalinoConnection();
    });



   /* Future.delayed(Duration(seconds: 5), (){
       setupBitalinoConnection();
    });*/

   try{
      BluetoothConnection.toAddress(arduinoMacAddress)
          .then((newConnection) {
        connection = newConnection;
        setState(() {});
      });
    }
    catch(e){
      print("$e");
    }

  }
@override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    bitalinoController.dispose();   //TODO learn plux's use of dispose and disconnect
    textFieldController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        body: Container(
          margin: EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: ListView(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  vitalsMonitorBoxes(),
                  SizedBox(
                    height: 6,
                  ),
                  Flex(
                    direction: Axis.horizontal,
                    children: <Widget>[
                      Container(
                        width: 300,
                        child: TextField(
                          decoration: new InputDecoration(labelText: "Enter your LOP measurement"),
                          keyboardType: TextInputType.number,
                          controller: textFieldController,
                        ),
                      ),
                      GestureDetector(
                        child: Container(
                          height: 30,
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.green[300],
                          ),
                          child: Center(child: Text('Set LOP',style: TextStyle(color: Colors.white),)),
                        ),
                        onTap: (){
                            if(textFieldController.text.isNotEmpty){
                              if(int.parse(textFieldController.text)>=90 && int.parse(textFieldController.text)<=140){
                                setState(() {
                                  lop = textFieldController.text;
                                });
                              }
                              else{
                                Utilities.showSnackBar(_scaffoldKey, "Safe values are between 90 and 140");
                              }
                            }
                            else{
                              Utilities.showSnackBar(_scaffoldKey, "Please enter a value");
                            }


                        },
                      ),

                    ],
                  ),


                  changeCuffPressureButton(),
                  SizedBox(
                    height: 8,
                  ),
                  startStopSession(),
                  SizedBox(
                    height: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right:16.0, left:16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Current Pressure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w200),),
                        Text('Target Pressure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w200),),
                      ],
                    ),
                  ),
                  radialGauges(),
                  SizedBox(
                    height: 64,
                  ),

                  _continueButton()

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget chart(List<SensorValue> _data){
    return Column(
      children: <Widget>[
        new charts.TimeSeriesChart([
          charts.Series<SensorValue, DateTime>(
            id: 'Values',
            colorFn: (_, __) => charts.MaterialPalette.gray.shade400,   // green.shadeDefault
            domainFn: (SensorValue values, _) => values.time,
            measureFn: (SensorValue values, _) => ((values.value)-500).abs(),
            data: _data,
          )
        ],
            animate: false,
            primaryMeasureAxis: charts.NumericAxisSpec(
              tickProviderSpec:
              charts.BasicNumericTickProviderSpec(zeroBound: false),
              viewport: new charts.NumericExtents(0, 600),
            ),
            domainAxis: new charts.DateTimeAxisSpec(
                renderSpec: new charts.NoneRenderSpec()))
      ],
    );






  }
  Stream<int> stopWatchStream() {
    StreamController<int> streamController;
    Timer timer;
    Duration timerInterval = Duration(seconds: 1);
    int counter = 0;

    void startTimer() {
      timer = Timer.periodic(timerInterval, (_) {
        counter++;
        streamController.add(counter);
      });
    }

    void stopTimer() {
      if (timer != null) {
        timer.cancel();
        timer = null;
        counter = 0;
        streamController.close();
      }
    }

    streamController = StreamController<int>(
      onListen: startTimer,
      onCancel: stopTimer,
      onPause: stopTimer,
      onResume: startTimer,
    );
    return streamController.stream;
  }
  Widget _continueButton(){
    return Container(
      height: 50,
      width: 350,
      child: RaisedButton(
        child: Text(
          'Show EMG Analysis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        //color: Color(0xffbfa6f82),
        color: Colors.green,
        textColor: Colors.white,
        onPressed: () async{
         // bitalinoController.stop();
          await bitalinoController.disconnect();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EmgAnalyticsPage()),
          );

        },
      ),
    );

  }
  Widget startStopSession() {
    timeStream = stopWatchStream();
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Color(0xffbecf1f6),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            offset: Offset(0.0, 0.0), //(x,y)
            blurRadius: 1.0,
          ),
        ],
      ),
      child: Flex(
        direction: Axis.vertical,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Text(
              'BFR Exercise',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: RaisedButton(
              child: Text('${isSessionStarted ? 'Stop' : 'Start'}'),
              color: Colors.lightBlueAccent,
              onPressed: () async {
               // inflateCuff();
               /*if(!isAcquisitionStarted && isBitalinoConnected){
                 isAcquisitionStarted = await startBitalino(samplingRate: Frequency.HZ100,
                      numberOfSamples: 10);
                }*/
                if(isBitalinoConnected && !isSessionStarted){
                  await startBitalino(samplingRate: Frequency.HZ100,
                      numberOfSamples: 5);
                  isAcquisitionStarted = true;
                }

                if (!isSessionStarted && isAcquisitionStarted) {
                  startTimer();
                  isSessionStarted = true;
                } else {
                 bool bitStopped = await bitalinoController.stop();
                  stopTimer();
                  isSessionStarted = false;
                  isAcquisitionStarted = false;
                  await openValve();

                  setState(() {
                    cuffPressure = 0;
                  });

                }


              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0, left: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Exercise Duration:',
                    style: TextStyle(
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                  ),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(
                          '$hrsStr:$minStr:$secStr',
                          style: TextStyle(
                            fontSize: 20,
                            letterSpacing: 1,
                            backgroundColor: (timeElapsed < 60)||(!isSessionStarted)
                                ? null
                                : Color(0xffbfa6f82), //when a minute is up
                            color:
                            (timeElapsed < 60)||(!isSessionStarted) ? Colors.black : Colors.white,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void startTimer() {
    timerStreamSubscription = timeStream.listen((int newTick) {
      timeElapsed = newTick;
      setState(() {
        hrsStr = ((newTick / (60 * 60)) % 60).floor().toString().padLeft(2, '0');
        minStr = ((newTick / 60) % 60).floor().toString().padLeft(2, '0');
        secStr = (newTick % 60).floor().toString().padLeft(2, '0');
      });
    });
  }

  void stopTimer() {
    timerStreamSubscription.cancel();
    setState(() {
      hrsStr = '00';
      minStr = '00';
      secStr = '00';
    });

  }

  Widget biometricDisplayBox({String label, String value, String icon}) {
    return Container(
      padding: EdgeInsets.only(top: 4, bottom: 4),
      width: 70,
      height: 130,
      decoration: BoxDecoration(
        color: Color(0xffbfa6f82),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
         Text(
            '$label',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Image.asset(
            "assets/$icon",
            width: 50,
            height: 60,
            fit: BoxFit.contain,
            color: Colors.white,
          ),
        Text(
            '$value',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget vitalsMonitorBoxes() {
    return Flex(
      direction: Axis.horizontal,
      children: <Widget>[
        Expanded(
          child: biometricDisplayBox(
              label: "Heart Rate", value: '78', icon: "heart_icon.png"),
          flex: 1,
        ),
        SizedBox(
          width: 8,
        ),
        Expanded(
          child: biometricDisplayBox(
              label: "LOP", value: lop, icon: "pressure_icon.png"),
          flex: 1,
        ),
      ],
    );
  }

  Widget changeCuffPressureButton() {
    return Container(
      padding: EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        //color: Color(0xffbecf1f6),
        color: Color(0xffffe5e5),
        borderRadius: BorderRadius.circular(14),
        // border: Border.all(color: Colors.white70),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "LOP % ",
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.w300,
            ),
          ),
          // SizedBox(width: 15,),
          pillButton(),
          IconButton(icon: Icon(Icons.send),
          onPressed: () async {
                try {
                  connection.output.add(utf8.encode(cuffPressure.toString() + "\r\n"));
                  await connection.output.allSent;
                  print("Pressure set to $cuffPressure mmHg");
                  Utilities.showSnackBar(_scaffoldKey, "Pressure set to $cuffPressure mmHg");

                } catch (error) {
                  print("THis errrrrrror occured $error");
                  Utilities.showSnackBar(_scaffoldKey, "Error setting Pressure");
                }
          },)
        ],
      ),
    );
  }
  Widget pillButton() {
    return Container(
      height: 40,
      width: 120,
      padding: EdgeInsets.only(left: 0, right: 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xffbecf1f6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.elliptical(100, 120),
            bottomLeft: Radius.elliptical(100, 120),
            topRight: Radius.circular(100),
            bottomRight: Radius.circular(100),
          ),
        ),
        child: Flex(
          direction: Axis.horizontal,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: FlatButton(
                padding: EdgeInsets.only(left: 4),
                onPressed: () {
                  setState(() {
                    decreaseCuffPressure();
                  });
                },
                child: Icon(
                  Icons.remove,
                  color: Colors.red,
                ),
              ),
            ),
            Expanded(
                flex: 3,
                child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.elliptical(100, 120),
                        bottomLeft: Radius.elliptical(100, 120),
                        topRight: Radius.circular(100),
                        bottomRight: Radius.circular(100),
                      ),
                    ),
                    child: Center(
                        child: Text('$lopPercentage',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w300,
                                fontSize: 18))))),
            Expanded(
              flex: 2,
              child: FlatButton(
                padding: EdgeInsets.only(right: 4),
                onPressed: () {
                  setState(() {
                    increaseCuffPressure();
                  });
                },
                child: Icon(
                  Icons.add,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget radialGauges() {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 4),
      width: 250,
      height: 200,
      decoration: BoxDecoration(
        color: Color(0xff414A4C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            offset: Offset(0.0, 0.5), //(x,y)
            blurRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: SfRadialGauge(
              enableLoadingAnimation: true,
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  startAngle: 270,
                  endAngle: 270,
                  showLabels: false,
                  showTicks: false,
                  radiusFactor: 1.0,
                  canScaleToFit: true,
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                        axisValue: 20,
                        positionFactor: 0.1,
                        widget: Text(
                          '$cuffPressure',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey),
                        )),
                        GaugeAnnotation(
                            axisValue: 0.5,
                            verticalAlignment: GaugeAlignment.far,
                              positionFactor: 0.1,
                              angle: 0,
                              //widget: Text('Cuff Pressure', style: TextStyle(color: Colors.white),),
                          )
                  ],
                  axisLineStyle: AxisLineStyle(
                    //color: Color(0xffffe5e5),
                    thickness: 0.18,
                    cornerStyle: CornerStyle.bothCurve,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                        color: Color(0xffff4c4c),
                        value: cuffPressure.toDouble(),
                        cornerStyle: CornerStyle.bothCurve,
                        width: 0.08,
                        pointerOffset: 0.1,
                        sizeUnit: GaugeSizeUnit.factor,
                        enableAnimation: true,
                        gradient: const SweepGradient(colors: <Color>[
                          Color(0xFFff7f7f),
                          Color(0xffff0000),
                        ], stops: <double>[
                          0.5,
                          0.80
                        ])),
                    RangePointer(
                        color: Colors.blueAccent,
                        value: cuffPressure.toDouble(),
                        cornerStyle: CornerStyle.bothCurve,
                        width: 0.08,
                        pointerOffset: 0.0,
                        sizeUnit: GaugeSizeUnit.factor,
                        enableAnimation: true,
                        gradient: const SweepGradient(colors: <Color>[
                          Colors.blue,
                          Colors.lightBlueAccent
                        ], stops: <double>[
                          0.5,
                          0.80
                        ])),
                    MarkerPointer(
                      value: cuffPressure.toDouble(),
                      markerType: MarkerType.circle,
                      color: const Color(0xFFff9999),
                      markerWidth: 10,
                      markerHeight: 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: 180,
              height: 200,
              child: SfRadialGauge(
                enableLoadingAnimation: true,
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: lopPercentage*0.01*int.parse(lop).toDouble(),
                    startAngle: 270,
                    endAngle: 270,
                    showLabels: false,
                    showTicks: false,
                    radiusFactor: 0.7,
                    canScaleToFit: true,
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                          positionFactor: 0.1,
                          angle: 0,
                          widget: Text(
                            '${(lopPercentage*0.01*int.parse(lop)).floor()}',
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w300,
                                color: Colors.grey),
                          ))
                    ],
                    axisLineStyle: AxisLineStyle(
                      color: Color(0xffffe5e5),
                      thickness: 0.20,
                      cornerStyle: CornerStyle.bothCurve,
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                          color: Color(0xffff4c4c),
                          value: cuffPressure.toDouble(),
                          cornerStyle: CornerStyle.bothCurve,
                          width: 0.08,
                          pointerOffset: 0.1,
                          sizeUnit: GaugeSizeUnit.factor,
                          enableAnimation: true,
                          gradient: const SweepGradient(colors: <Color>[
                            Color(0xFFff7f7f),
                            Color(0xffff0000),
                          ], stops: <double>[
                            0.5,
                            0.80
                          ])),
                      RangePointer(
                          color: Colors.lightGreen,
                          value: cuffPressure.toDouble(),
                          cornerStyle: CornerStyle.bothCurve,
                          width: 0.08,
                          pointerOffset: 0.0,
                          sizeUnit: GaugeSizeUnit.factor,
                          enableAnimation: true,
                          gradient: const SweepGradient(
                              colors: <Color>[Colors.greenAccent, Colors.green],
                              stops: <double>[0.5, 0.80])),
                      MarkerPointer(
                        value: cuffPressure.toDouble(),
                        markerType: MarkerType.circle,
                        color: const Color(0xFFff9999),
                        markerWidth: 10,
                        markerHeight: 10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void increaseCuffPressure() {
    lopPercentage += 10;
    if (lopPercentage > 80) {
      lopPercentage = 80;
    }
  }

  void decreaseCuffPressure() {
    lopPercentage -= 10;
    if (lopPercentage < 40) {
      lopPercentage = 40;
    }
  }

  Future<void> initPlatformState() async {
    bitalinoController =
        BITalinoController(bitalinoMacAddress, CommunicationType.BTH);
    try {
      await bitalinoController.initialize();
      Utilities.showSnackBar(_scaffoldKey, "Initialized: BTH");
    } catch (Exception) {
      Utilities.showSnackBar(_scaffoldKey, "Initialized failed");
    }
  }

  Future<void> setupBitalinoConnection() async {
    isBitalinoConnected = await bitalinoController.connect(onConnectionLost: () {
      Utilities.showSnackBar(_scaffoldKey, 'Connection lost');
    });


    Utilities.showSnackBar(_scaffoldKey, "${isBitalinoConnected?'Bitalino Connected':'Bitalino not Connected'}");

  }

  Future<void> startBitalino({Frequency samplingRate,  int numberOfSamples}) async {
    await bitalinoController.start( // Im doing this in the hope to solve the radial gauge reading problem
      [0],
      samplingRate,
      numberOfSamples: numberOfSamples, // for now this is a good number
      onDataAvailable: (frame)  async {
        cuffPressure = frame.analog[0];
        cuffPressure = (((cuffPressure - 7) * 349.2862) ~/ 1023 );
        setState(() {});

        // TODO: Nsert code for checking delflation
      },
    );
    await bitalinoController.stop();

    await closeValve();
    await  turnOnPump();
    print ("onnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn");
    await bitalinoController.start(
      [0],
      samplingRate,
      numberOfSamples: numberOfSamples, // for now this is a good number
      onDataAvailable: (frame)  async {
        cuffPressure = frame.analog[0];
        cuffPressure = (((cuffPressure - 7) * 349.2862) ~/ 1023 );
        print("Cuff Pressure: $cuffPressure");
        setState(() {});

        double desiredPressure = lopPercentage*0.01*int.parse(lop);
        if(cuffPressure> desiredPressure+10){
          await bitalinoController.stop();
          print("desired Pressure : $cuffPressure");
          await turnOffPump();
          await bitalinoController.start(
            [0],
            samplingRate,
            numberOfSamples: numberOfSamples, // for now this is a good number
            onDataAvailable: (frame)  async {
              cuffPressure = frame.analog[0];
              cuffPressure = (((cuffPressure - 7) * 349.2862) ~/ 1023 );
             setState(() {});

              // TODO: Nsert code for checking delflation
            },
          );

        }
      },
    );

  }



  Future<bool> stopBitalino() async {
    bool stopped = await bitalinoController.stop();
    if (stopped) Utilities.showSnackBar(_scaffoldKey, "Bitalino Stopped");
    return stopped;
  }
  // TODO: PUt it in a utilitiess class
  Future<bool> turnOnPump() {
    return bitalinoController.pwm(255);
  }
  Future<bool> turnOffPump() {
    return bitalinoController.pwm(0);
  }

  Future<void> closeValve() async {
    await bitalinoController.setDigitalOutputs([1,1]);
  }
  Future<void> openValve() async {
    await bitalinoController.setDigitalOutputs([0,0]);
  }


}
