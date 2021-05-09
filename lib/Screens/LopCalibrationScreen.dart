import 'dart:convert';
import 'dart:async';
import 'package:bitalino/bitalino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:smart_cuff/BottomNavigationItems/WorkoutTabbedPage.dart';
import 'package:smart_cuff/HelperClasses/Utilities.dart';
import 'dart:typed_data';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:smart_cuff/Tabs/DashBoard.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

enum CalibrationStatus { not_started, started, inProgress, finished, failed }

class LopCalibrationScreen extends StatefulWidget {
  @override
  _LopCalibrationScreenState createState() => _LopCalibrationScreenState();
}
class _LopCalibrationScreenState extends State<LopCalibrationScreen> {
  String deviceName = "Arduino ESP2";
  bool espBonded = true;
  List<BluetoothDevice> devices;
  //String espMacAddress = "C4:4F:33:69:C4:87";
  final String espMacAddress = "7C:9E:BD:E3:D0:7E";
  final String bitalinoMacAddress = "98:D3:21:FC:8B:72";
  //String bitalinoMacAddress = "98:D3:51:FD:9D:72";
  BluetoothConnection espConnection;
  BITalinoController bitalinoController;
  bool isEspConnected = false;
  bool isBitalinoConnected=false;
  bool isPressureValveClosed = false;
  bool isPumpOn = false;
  int cuffPressure = 0;
  int inflateTo= 0;
  final TextEditingController textEditingController =
      new TextEditingController();
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  bool isCalibrating = false;
  int timeSinceCalibration = 0;
  Timer calibrationTimer;
  String receivedData;
  final CALIBRATION_DEADLINE = 180;
  bool isAcquisitionStarted = false;

  String lop = '105';
  Timer espListenTimer;
  bool calibrationComplete = false;
  bool isCalibrationSuccess = false;
  @override
  void initState() {
    // TODO: implement initState
    FlutterBluetoothSerial.instance
        .setPairingRequestHandler((BluetoothPairingRequest request) {
      print("Trying to auto-pair with Pin 1234");
      if (request.pairingVariant == PairingVariant.Pin) {
        return Future.value("1234");
      }
      return null;
    });
    connectEsp();
    initPlatformState();
    setupBitalinoConnection();
    super.initState();
  }
@override
  void dispose() {
    // TODO: implement dispose
  espConnection.dispose();
  bitalinoController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text("Cuff Inflation",
            style:
                TextStyle(color: Colors.red[300], fontWeight: FontWeight.w400)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.refresh, color: Colors.red[300],),
              onPressed: () async {
                connectEsp();
                setupBitalinoConnection();
              }
          ),
        ],
      ),
      body:
          /*Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              RaisedButton(
                child: Text("Dolemite"),
                onPressed: () async {
                  try {
                        if (!espBonded) {
                      espBonded = await FlutterBluetoothSerial.instance
                          .bondDeviceAtAddress(bitalinoMacAddress);
                      print(
                          'Bonding with ${deviceName} has ${espBonded ? 'succeed' : 'failed'}.');

                      BluetoothConnection.toAddress(bitalinoMacAddress)
                          .then((newConnection) {
                        //  print('Connected to your device');
                        connection = newConnection;
                        isEspConnected = connection.isConnected;
                        setState(() {});
                        print('Connected to your device $isEspConnected');
                      });
                    }

                    if (espBonded) {

                    } else {
                      espBonded = await FlutterBluetoothSerial.instance
                          .removeDeviceBondWithAddress(espMacAddress);
                      espBonded = !espBonded;
                      isEspConnected = connection.isConnected;
                    }
                  } catch (ex) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Error occurred while bonding'),
                          content: Text("${ex.toString()}"),
                          actions: <Widget>[
                            new FlatButton(
                              child: new Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
              SizedBox(
                width: 50,
              ),
              RaisedButton(
                child: Text("Disconnect"),
                onPressed: () async {
                  try {
                    if (isEspConnected) {
                      connection.dispose();
                      isEspConnected = connection.isConnected;
                      print(
                          'Disconnection has ${isEspConnected ? 'succeed' : 'failed'}.');
                    }

                    if (espBonded) {
                      //because bonded might still be false even after trying to bond
                      BluetoothConnection.toAddress(espMacAddress)
                          .then((newConnection) {
                        //  print('Connected to your device');
                        connection = newConnection;
                        isEspConnected = connection.isConnected;
                        setState(() {});
                        print('Connected to your device $isEspConnected');
                      });
                    }
                  } catch (ex) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Error occurred while bonding'),
                          content: Text("${ex.toString()}"),
                          actions: <Widget>[
                            new FlatButton(
                              child: new Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 16.0),
            child: TextField(
              style: const TextStyle(fontSize: 15.0),
              controller: textEditingController,
              decoration: InputDecoration.collapsed(
                hintText: "Enter pressure value to send",
                hintStyle: const TextStyle(color: Colors.grey),
              ),
              enabled: isEspConnected,
            ),
          ),

          RaisedButton(
            child: Text(
              "Send",
            ),
            onPressed: () async {
              if (connection.isConnected) {
                if (textEditingController.text.isNotEmpty) {
                  String pressureValue = textEditingController.text;
                  try {
                    pressureValue = pressureValue.trim();
                    connection.output.add(utf8.encode(pressureValue + "\r\n"));
                    await connection.output.allSent;
                  } catch (error) {
                    print("THis errrrrrror occured $error");
                  }
                  textEditingController.clear();
                } else {
                  print("No value to send");
                }
              }
            },
          ),
          SizedBox(height: 10,)
        ],
      ),*/
           calibrationBody()
               /*Center(
                  child: Container(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        semanticsLabel: "Connecting to ESP",
                        strokeWidth: 10,
                        valueColor:
                            new AlwaysStoppedAnimation<Color>(Colors.red),
                      ))),*/
    );
  }

  Widget calibrationBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              '''Turn-on your Oxymeter  
     and press calibrate''',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.black45,
                  fontWeight: FontWeight.w300),
            ),
            SizedBox(
              height: 16,
            ),
            isCalibrating
                ? liquidCircularProgressIndicator()
                : GestureDetector(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadiusDirectional.circular(80),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.red[200]]),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(0.0, 1.0), //(x,y)
                            blurRadius: 9.0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Calibrate',
                          style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w100),
                        ),

                      ),
                    ),
                    onTap: () {
                      startCalibration();
                    },
                  ),
            SizedBox(height: 80,),
            radialGaugePressureStyle(),
            SizedBox(height: 40,),
           isCalibrating?Text("   Calibrating LOP...", style: TextStyle(fontSize: 18, color: Colors.black26),):(isCalibrationSuccess && !isCalibrating)?
           Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                Icon(Icons.beenhere, color: Colors. green,),
                Text("Calibration Complete!",style: TextStyle(fontSize: 18, color: Colors.green,)),
              ],),
              Text("Your approx LOP is $lop mmHg",style: TextStyle(fontSize: 22, color: Colors.green,fontWeight: FontWeight.w100)),

            ],
           ):Text(''),

            SizedBox(height: 20,),
            _continueButton(),

          ],
        ),
      ),
    );
  }

  Widget _continueButton(){
    return Container(
      height: MediaQuery.of(context).size.height/20,
      width: MediaQuery.of(context).size.width/0.5,
      child: RaisedButton(
        child: Text(
          'Continue',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Color(0xffbfa6f82),
        textColor: Colors.white,
        onPressed: () async{
            //bitalinoController.stop();

          //await bitalinoController.disconnect();
          await bitalinoController.disconnect();
          await bitalinoController.dispose();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashBoard(lop: lop,)),
            );
        },
      ),
    );
  }
  Future<void> bondEsp() async {
    try {
      if (!espBonded) {
        espBonded = await FlutterBluetoothSerial.instance
            .bondDeviceAtAddress(espMacAddress);
        setState(() {});
      }
    } catch (e) {
      Utilities.showSnackBar(scaffoldKey, e.toString());
    }
  }
  Widget radialGaugePressureStyle() {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 4),
      width: 250,
      height: 200,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: SfRadialGauge(
              enableLoadingAnimation: true,
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 180,
                  startAngle: 180,
                  endAngle: 0,
                  showLabels: true,
                  showTicks: true,
                  radiusFactor: 1.5,
                  canScaleToFit: true,
                  ticksPosition: ElementsPosition.outside,
                  labelsPosition: ElementsPosition.outside,
                  useRangeColorForAxis: true,
                  interval: 20,
                  axisLabelStyle:GaugeTextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 8),
                  majorTickStyle: MajorTickStyle(length: 0.10,
                      lengthUnit: GaugeSizeUnit.factor,
                      thickness: 2),
                  minorTicksPerInterval: 4, labelOffset: 15,
                  minorTickStyle: MinorTickStyle(length: 0.04,
                      lengthUnit: GaugeSizeUnit.factor,
                      thickness: 1),
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                        axisValue: cuffPressure.toDouble(),
                        positionFactor: 0.5,
                        widget: Text(
                          'Cuff Pressure: $cuffPressure',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w200,
                              color: Colors.grey),
                        ),
                        angle: 90),
                  ],
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.12,
                    cornerStyle: CornerStyle.bothFlat,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    NeedlePointer(value: cuffPressure.toDouble(), needleLength: 0.6,
                        enableDragging: true,
                      enableAnimation: true,
                      gradient: const LinearGradient(
                          colors: <Color>[
                            Color(0xFFFF6B78), Color(0xFFFF6B78),
                            Color(0xFFE20A22), Color(0xFFE20A22)],
                          stops: <double>[0, 0.5, 0.5, 1]),
                        needleColor: const Color(0xFFF67280),
                        knobStyle: KnobStyle(
                            knobRadius: 0.08,
                            sizeUnit: GaugeSizeUnit.factor,
                            color: Colors.black)

                    ),
                  ],
                  ranges: <GaugeRange>[

                    GaugeRange(startValue: 0,endValue: 180,color: Colors.green,startWidth: 5,endWidth:15,rangeOffset: 0.1,
                        gradient: const SweepGradient(colors: <Color>[
                          Color(0xFFA5D6A7),
                          Colors.greenAccent,
                          Colors.green,
                          Color(0xFFff7f7f),
                          Color(0xffff0000),

                        ], stops: <double>[
                          0.3,
                          0.5,
                          0.6,
                          0.7,
                          1
                        ])
                    ),
                    // GaugeRange(startValue: 100,endValue: 180,color: Colors.yellow[400],startWidth: 5,endWidth:15,rangeOffset: 0.1),
                    //GaugeRange(startValue: 180,endValue: 250,color: Colors.redAccent,startWidth: 5,endWidth:15,rangeOffset: 0.1),

                  ],


                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<bool> connectEsp() {
    try {
      BluetoothConnection.toAddress(espMacAddress).then((newConnection) {
        espConnection = newConnection;
        isEspConnected = espConnection.isConnected;
        setState(() {});
        Utilities.showSnackBar(scaffoldKey, 'Connected to ESP $isEspConnected');
        print("Esp connected $isEspConnected");
        return isEspConnected;
      });
    } catch (ex) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occurred while connecting ESP'),
            content: Text("${ex.toString()}"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
  Future<void> startCalibration() async {
    setState(() {isCalibrating = true; });
    await closeValve();
    //await resetEspConnection();
    Future.delayed(Duration(seconds: 3), () async {
      if (espConnection.isConnected) {
        Utilities.showSnackBar(scaffoldKey, "Calibrating");
        calibrationTimer = Timer.periodic(Duration(seconds: 1), (timer) {

            timeSinceCalibration++;
            if (timeSinceCalibration == CALIBRATION_DEADLINE) {
              timeSinceCalibration = 0;
              isCalibrating = false; //todo use enums because the final status of isCalibrating can be different than two vals
               bitalinoController.stop();
            }
            setState(() {});
        });

        if(!isAcquisitionStarted && isBitalinoConnected){
          try {
            sendCommandToEsp('calibrate');
            Future.delayed(Duration(seconds: 5), () async {
              espListenTimer = Timer.periodic(Duration(seconds:5), (timer) async {
                 await listenToEsp();
              });

            });
          } catch (error) {
            print("$error");
          }
        } else {
          Utilities.showSnackBar(scaffoldKey, "ESP IS NOT CONNECTED");
        }
        }

    });
  }

  Future<void> openValve() async {
    if(isPressureValveClosed){
      await bitalinoController.setDigitalOutputs([0,0]).whenComplete(() => Utilities.showSnackBar(scaffoldKey, "Valve Opened"));
      setState(() {
        isPressureValveClosed = false;
      });

    }
  }
/*  Future<void> pumpOff() async {
    if(!isPumpOn){
       await bitalinoController.pwm(255).whenComplete(() => Utilities.showSnackBar(scaffoldKey, "Valve Closed"));
      setState(() {
        isPressureValveClosed = true;
      });
    }
  }
  Future<void> pumpOn() async {
    if(isPumpOn){
      await bitalinoController.pwm(0).whenComplete(() => Utilities.showSnackBar(scaffoldKey, "Valve Opened"));
      setState(() {
        isPressureValveClosed = false;
      });

    }
  }*/
  Future<void> closeValve() async {
    if(!isPressureValveClosed){
      await bitalinoController.setDigitalOutputs([1,1]).whenComplete(() => Utilities.showSnackBar(scaffoldKey, "Valve Closed"));
      setState(() {
        isPressureValveClosed = true;
      });
    }
  }

  Future<void> sendCommandToEsp(String command) async {
    espConnection.output.add(utf8.encode(command + "\r\n"));
    await espConnection.output.allSent;
}
  Future<void> listenToEsp() {
    espConnection.input.listen((Uint8List data) async {
        receivedData = ascii.decode(data).trim().toString();
        if(receivedData=="fail"){
          print('Calibration failed');
          Utilities.showSnackBar(scaffoldKey, "Calibration Failed");
          bitalinoController.stop();
          setState(() {
            isCalibrating = false;
            espListenTimer.cancel();
            lop = 'Not determined';
          });
          await openValve();
        }
        else if(receivedData.trimLeft().substring(0, 8)=="inflate="){
          inflateTo = int.parse(receivedData.trimLeft().substring(8)) ;
          Utilities.showSnackBar(scaffoldKey, "Inflating to: $inflateTo");
          setState(() {});
           startBitalino(samplingRate: Frequency.HZ100,
              numberofSamples: 5);

        }
        else if(receivedData.trimLeft().substring(0, 12)=="LOP_success:"){
            String lop_calculated = receivedData.substring(12).trim();
            Utilities.showSnackBar(scaffoldKey, '$lop_calculated');
            await openValve();
            //await bitalinoController.disconnect();
            //bitalinoController.dispose();
            espConnection.dispose();
            setState(() {
              isCalibrating = false;
              isCalibrationSuccess = true;
              espListenTimer.cancel();
              calibrationTimer.cancel();
              lop = lop_calculated;
            });

        }


    });
  }
  Future<void> resetEspConnection() async {
    await sendCommandToEsp("reset");
    espConnection.dispose();
    await Future.delayed(Duration(seconds: 7), () {
      //if you dont wait long enough for connectEsp to finish, espconneection.isconnected is not updated
      connectEsp();
    });
  }
  Widget liquidCircularProgressIndicator() {
    return Container(
      width: 120,
      height: 120,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadiusDirectional.circular(80),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.red[200]]),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              offset: Offset(0.0, 1.0), //(x,y)
              blurRadius: 9.0,
            ),
          ],
        ),
        child: LiquidCircularProgressIndicator(
          value: (timeSinceCalibration / CALIBRATION_DEADLINE) * 100,
          valueColor: AlwaysStoppedAnimation(Colors.green[50]),
          backgroundColor: Colors.red[200],
          // borderColor: Colors.red,
          // borderWidth:2.0,
          direction: Axis.vertical,
          center: Text(
            isCalibrating?'Calibrating...':'Calibrate',
            style: TextStyle(
                fontSize: 18,
                color: Colors.pinkAccent,
                fontWeight: FontWeight.w100),
          ),
        ),
      ),
    );
  }
  Widget liquidLinearProgressIndicator() {
    return Container(
      height: 20,
      width: 200,
      child: LiquidLinearProgressIndicator(
        value: (timeSinceCalibration / CALIBRATION_DEADLINE) * 100,
        valueColor: AlwaysStoppedAnimation(Colors.pink),
        backgroundColor: Colors.white,
        borderColor: Colors.red,
        borderWidth: 3.0,
        borderRadius: 12.0,
        direction: Axis.horizontal,
        center: Text(
          ((timeSinceCalibration / CALIBRATION_DEADLINE) * 100)
                  .toInt()
                  .toString() +
              "%",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
    );
  }
  Future<void> initPlatformState() async {
    bitalinoController =
        BITalinoController(bitalinoMacAddress, CommunicationType.BTH);
    try {
      await bitalinoController.initialize();
    } catch (Exception) {
      Utilities.showSnackBar(scaffoldKey, "Initialized failed");
    }
  }
  Future<void> setupBitalinoConnection() async {
    try {
      isBitalinoConnected =
      await bitalinoController.connect(onConnectionLost: () {
        Utilities.showSnackBar(scaffoldKey, "Bitalino Connection Lost");
        setState(() {
          isBitalinoConnected = false;
        });
      });
      Utilities.showSnackBar(scaffoldKey, isBitalinoConnected?"Bitalino is connected":"Unable to connect to Bitalino");
      setState(() {
      });
    }
    on BITalinoException catch (e) {
      Utilities.showSnackBar(scaffoldKey, e.msg.toString());
      if (e.type == BITalinoErrorType.BT_DEVICE_FAILED_CONNECT) {
        Utilities.showSnackBar(scaffoldKey, "Bitalino failed to connect");
        bitalinoController.disconnect();
        await initPlatformState();    //todo this might be wrong
        isBitalinoConnected = await bitalinoController.connect();
      }
      if (e.type == BITalinoErrorType.LOST_CONNECTION) {
        await bitalinoController.stop();
        await bitalinoController.dispose();
        await initPlatformState();
      }
      if (e.type == BITalinoErrorType.BT_DEVICE_ALREADY_CONNECTED) {
        Utilities.showSnackBar(scaffoldKey, "Bitalino is already connected");

      }
    }

  }

/*  Future<bool> checkDeflation({Frequency samplingRate,  int numberOfSamples})async{
    return bitalinoController.start(
      [0,1],
      samplingRate,
      numberOfSamples: numberOfSamples, // For now this is a good number
      onDataAvailable: (frame)  async {
        cuffPressure = frame.analog[0];
        cuffPressure = ((cuffPressure - 22) * 349.2862) ~/ 1023 ;
        print(cuffPressure);
        if(cuffPressure<=10) {
          await bitalinoController.stop();
          print("doooooooooooooooooooollllllllllllllllllmiiiiiiiiiiiiiiooooooo");
          await closeValve();
          *//* await startBitalino(samplingRate: Frequency.HZ100,
              numberOfSamples: 10);*//*
        }
        espConnection.output.add(utf8.encode("set="+cuffPressure.toString() + "\r\n"));
        espConnection.output.allSent;
        print("Pressure set to $cuffPressure mmHg");
        setState(() {});
      },
    );
  }*/
Future<void> startBitalino({Frequency samplingRate,  int numberofSamples}) async {
    await closeValve();
    await  turnOnPump();
    await bitalinoController.start(

      [0],
      samplingRate,
      numberOfSamples: numberofSamples, // for now this is a good number
      onDataAvailable: (frame)  async {
        cuffPressure = frame.analog[0];
        cuffPressure = (((cuffPressure - 7) * 349.2862) ~/ 1023 );
        print("Cuff Pressure: $cuffPressure");
        setState(() {});
        if(cuffPressure>inflateTo+15){
          print("the last cuff pressure value: $cuffPressure");
          espConnection.output.add(utf8.encode("set="+cuffPressure.toString() + "\r\n"));
          espConnection.output.allSent;
          await bitalinoController.stop();
          print("qqqqqqqqqqqqqqq: $cuffPressure");
          await turnOffPump();
          print("pressure set to $cuffPressure mmhg");

        }
      },
    );

  }
  /*Future<void> startBitalino({Frequency samplingRate,  int numberOfSamples}) async {
    await bitalinoController.start(
      [0,1],
      samplingRate,
      numberOfSamples: numberOfSamples, // For now this is a good number
      onDataAvailable: (frame)  async {
        cuffPressure = frame.analog[0];
        cuffPressure = (((cuffPressure - 7) * 349.2862) ~/ 1023 );
        setState(() {});
        if(cuffPressure>140+15){
          print("The last cuff pressure value: $cuffPressure");
          await bitalinoController.stop();
          await turnOffPump();
        }
        print("Pressure set to $cuffPressure mmHg");
        Future.delayed(Duration(seconds: 1));
        print("senay died hereeeeeeeeee");
        bitalinoController.start(
          [0,1],
          samplingRate,
          numberOfSamples: numberOfSamples, // For now this is a good number
          onDataAvailable: (frame)  async {
            cuffPressure = frame.analog[0];
            cuffPressure = (((cuffPressure - 7) * 349.2862) ~/ 1023 );
            setState(() {});
            espConnection.output.add(utf8.encode("set="+cuffPressure.toString() + "\r\n"));
            espConnection.output.allSent;
            print("Pressure set to $cuffPressure mmHg");
            print("Senay was hererrrrrrrrrrrr");

          },
        );
      },
    );

  }*/
  void stopBitalino() async {
    bitalinoController.stop().then((value) {
      if(value)Utilities.showSnackBar(scaffoldKey, "Bitalino Stopped");
      else Utilities.showSnackBar(scaffoldKey, "Bitalino failed to stop");
    });

  }
  Future<bool> turnOnPump() {
    return bitalinoController.pwm(255);
  }
  Future<bool> turnOffPump() {
    return bitalinoController.pwm(0);
  }

}
