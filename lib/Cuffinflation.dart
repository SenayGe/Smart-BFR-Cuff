import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:bitalino/bitalino.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:smart_cuff/HelperClasses/Utilities.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
class CuffInflation extends StatefulWidget {
  @override
  _CuffInflationState createState() => _CuffInflationState();
}

class _CuffInflationState extends State<CuffInflation> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String espMacAddress = "7C:9E:BD:E3:D0:7E";
  String bitalinoMacAddress = "98:D3:51:FD:9D:72";
  BluetoothConnection espConnection;
  BITalinoController bitalinoController;
  BluetoothConnection connection;
  bool isEspConnected = false;
  bool isBitalinoConnected=false;
  int cuffPressure = 0;
  bool calibrating = false;
  bool confirmingSpo2Connection = false;
  int timeSinceCalibration = 0;
  Timer counterTimer;
  Timer spo2ConnectionConfirmationTimer;
  int counter = 0;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    bitalinoController.dispose();
    espConnection.dispose();
  }
  @override
  void initState() {
    // TODO: implement initState
/*    FlutterBluetoothSerial.instance
        .setPairingRequestHandler((BluetoothPairingRequest request) {
      print("Trying to auto-pair with Pin 1234");
      if (request.pairingVariant == PairingVariant.Pin) {
        return Future.value("1234");
      }
      return null;
    });*/
    initPlatformState();
    setupBitalinoConnection();
    setupEspConnection();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text("Cuff Inflation"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: (){
                setupEspConnection();
                setupBitalinoConnection();
            }
          ),
        ],
      ),
      body: cuffInflationScreenBody(),
    );
  }

  /*Widget dolemiteBody() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            RaisedButton(
              child: Text("Dolemite"),
              onPressed: () async {
                try {
                      if (!bonded) {
                      bonded = await FlutterBluetoothSerial.instance
                          .bondDeviceAtAddress(bitalinoMacAddress);
                      print(
                          'Bonding with ${deviceName} has ${bonded ? 'succeed' : 'failed'}.');

                      BluetoothConnection.toAddress(bitalinoMacAddress)
                          .then((newConnection) {
                        //  print('Connected to your device');
                        connection = newConnection;
                        isDeviceConnected = connection.isConnected;
                        setState(() {});
                        print('Connected to your device $isDeviceConnected');
                      });
                    }

                  if (espBonded) {
                    //because bonded might still be false even after trying to bond
                    BluetoothConnection.toAddress(espMacAddress)
                        .then((newConnection) {
                      //  print('Connected to your device');
                      connection = newConnection;
                      isEspConnected = connection.isConnected;
                      //setState(() {});
                      print('Connected to your device $isEspConnected');
                    });
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
                        'Disconnection has ${isEspConnected
                            ? 'succeed'
                            : 'failed'}.');
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
        )
      ],
    );
  }*/

  Widget cuffInflationScreenBody() {
    return SafeArea(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset("assets/pulseoxymeter_icon.png",
                      height: 80, width: 80, fit: BoxFit.fill),
                ),
                Text('''Please Turn on your PulseOxymeter,
                        Press Confirm''',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),),
                SizedBox(height: 8,),
                calibrating?liquidLinearProgressIndicator():RaisedButton(
                  child: Text("Calibrate"),
                  color: Colors.white,
                  textColor: Colors.lightBlue,
                  onPressed: ()async{
                     await resetAndDisconnectEsp();
                     //await setupEspConnection();
                     Utilities.showSnackBar(scaffoldKey, "Confirming...");
                     Future.delayed(Duration(seconds:10),() async {
                       calibrating = true;
                       setState(() {});
                       try{
                         espConnection.output.add(utf8.encode("calibrate"+"\r\n"));
                         await espConnection.output.allSent;
                        // espConnection.output.add(utf8.encode("ackFlag\r\n"));
                         //await espConnection.output.allSent;
                            setState(() {});
                       }
                       catch(e){
                         Utilities.showSnackBar(scaffoldKey, "Command not sent "+e.toString());
                         setState(() {
                           calibrating = false;
                         });
                       }

                       counterTimer = Timer.periodic(Duration(seconds: 1), (timer) {
                         counter++;
                         if(counter==30){
                           counter = 0;
                           counterTimer.cancel();
                           Utilities.showSnackBar(scaffoldKey, "Something wrong");
                           setState(() {
                             calibrating = false;
                           });
                         }
             /*            listenToEsp().then((data) async {
                           Utilities.showSnackBar(scaffoldKey, data);
                           if(data =="fail"){
                             counterTimer.cancel();
                             setState(() {
                               calibrating = false;
                             });
                             //confirm again
                           }
                           else if(data=="success"){
                             setState(() {
                               calibrating = false;
                             });
                           }
                         });*/

                       });
                     });

                  },
                ),
              //  liquidCircularProgressIndicator(),
                SizedBox(height: 10,),
               // liquidLinearProgressIndicator(),
                SizedBox(height: 10,),
                radialGauge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget liquidCircularProgressIndicator(){
    return  Container(
      width: 80,
      height: 80,
      child: LiquidCircularProgressIndicator(
        value:(timeSinceCalibration/30)*100,
        valueColor: AlwaysStoppedAnimation(Colors.pink),
        backgroundColor: Colors.white,
        borderColor: Colors.red,
        borderWidth:2.0,
        direction: Axis.vertical,
        center:Text(((timeSinceCalibration/30)*100).toInt().toString() +"%",style: TextStyle(fontSize:12.0,fontWeight: FontWeight.w600,color: Colors.black),),
      ),

    );
  }
  Widget liquidLinearProgressIndicator(){
    return Container(
      height: 20,
      width: 200,
      child: LiquidLinearProgressIndicator(
        value:(counter/30)*100,
        valueColor: AlwaysStoppedAnimation(Colors.pink),
        backgroundColor: Colors.white,
        borderColor: Colors.red,
        borderWidth: 3.0,
        borderRadius: 12.0,
        direction: Axis.horizontal,
        center:Text(((timeSinceCalibration/30)*100).toInt().toString() +"%",style: TextStyle(fontSize:16,fontWeight: FontWeight.w600,color: Colors.black),),

      ),
    );
  }
  Widget radialGauge() {
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
                  maximum: 250,
                  startAngle: 180,
                  endAngle: 0,
                  showLabels: true,
                  showTicks: true,
                  radiusFactor: 1.2,
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
                          '$cuffPressure',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
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
                      needleColor: Colors.black87,enableDragging: true,
                      enableAnimation: true,),
                  ],
                  ranges: <GaugeRange>[

                    GaugeRange(startValue: 0,endValue: 100,color: Colors.green,startWidth: 5,endWidth:15,rangeOffset: 0.1,
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

  Future<void> setupEspConnection(){
    try {
         BluetoothConnection.toAddress(espMacAddress)
            .then((newConnection) {
              setState(() {
                espConnection = newConnection;
                isEspConnected = espConnection.isConnected;
              });
              isEspConnected? Utilities.showSnackBar(scaffoldKey,"Esp Connected"):Utilities.showSnackBar(scaffoldKey,"Connecting to Esp...");
          print('Connected to Esp $isEspConnected');
        });

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
  }
  Future<String> listenToEsp(){
    espConnection.input.listen((Uint8List data){
      return ascii.decode(data).toString();
    });
  }
  Future<void> resetAndDisconnectEsp() async {
    espConnection.output.add(utf8.encode("reset"+"\r\n")); //this resets the esp device
    await espConnection.output.allSent;
    espConnection.dispose();
    setupEspConnection();
    setState(() {});
  }


  Future<void> initPlatformState() async {
    bitalinoController =
        BITalinoController(bitalinoMacAddress, CommunicationType.BTH);
    try {
      await bitalinoController.initialize();
      //Utilities.showSnackBar(scaffoldKey, "Initialized: BTH");
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
          calibrating = false;
        });
      });
    }
    on BITalinoException catch (e) {
      Utilities.showSnackBar(scaffoldKey, e.msg.toString());
      if (e.type == BITalinoErrorType.BT_DEVICE_FAILED_CONNECT) {
        bitalinoController.disconnect();
        await initPlatformState();
        isBitalinoConnected = await bitalinoController.connect();
      }
      if (e.type == BITalinoErrorType.LOST_CONNECTION) {
        await bitalinoController.stop();
        await bitalinoController.dispose();
        await initPlatformState();
      }
    }
    finally {
     // Utilities.showSnackBar(scaffoldKey, "Connected: $isBitalinoConnected");
    }
  }
  Future<bool> startBitalino({Frequency samplingRate,  int numberOfSamples}) async {
    return bitalinoController.start(
      [0, 1],
      samplingRate,
      numberOfSamples: numberOfSamples, // For now this is a good number
      onDataAvailable: (frame) {
        cuffPressure = frame.analog[1];
        cuffPressure = ((cuffPressure - 45) * 349.2862) ~/ 1023 + 6;
        espConnection.output.add(utf8.encode(cuffPressure.toString() + "\r\n"));
        espConnection.output.allSent;
       /* future() async{
          await espConnection.output.allSent;
          print("Pressure set to $cuffPressure mmHg");
        }
        future();*/
        setState(() {});

      },
    );
  }
  void stopBitalino() async {
    bitalinoController.stop().then((value) {
      if(value)Utilities.showSnackBar(scaffoldKey, "Bitalino Stopped");
      else Utilities.showSnackBar(scaffoldKey, "Bitalino failed to stop");
    });

  }

}
