 /*
import 'package:bitalino/bitalino.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_cuff/HelperClasses/Utilities.dart';
import 'package:smart_cuff/chart.dart';


class EmgAnalyticsPage extends StatefulWidget  {
  StreamSubscription<int> timerStreamSubscription;
  //Stream<int> timeStream;
  String timeStream;
  EmgAnalyticsPage({this.timeStream});

  @override
  _EmgAnalyticsPageState createState() => _EmgAnalyticsPageState(timeStream);

}

class _EmgAnalyticsPageState extends State<EmgAnalyticsPage> with AutomaticKeepAliveClientMixin<EmgAnalyticsPage> {
  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
  String timeStream;
_EmgAnalyticsPageState(this.timeStream);

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BITalinoController bitalinoController;
  int sequence = 0;
  List<SensorValue> data = [];
  List<SensorValue> data2 = [];
  DateTime previousTime;
  TextEditingController controller = TextEditingController();
  bool isSetup =false;
  bool isConnected;
  @override
   void initState()  {
    super.initState();
    //initPlatformState();

  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    //initPlatformState();
    */
/*if(!isSetup){
      future()async{
        await setupBitalinoConnection();
      }
      future();
    }
    future() async{
      await startBitalino(samplingRate: Frequency.HZ100,numberOfSamples: 200);
      print(' sssssssssssssssssssss');
    }
    future();*//*

    return Scaffold(
        key: _scaffoldKey,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text("$timeStream")
         */
/*   Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Chart(data),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Chart(data2),
              ),
            ),*//*

          ],
        ),
      );
  }
  Future<void> initPlatformState() async {
    bitalinoController = BITalinoController(
        "98:D3:51:FD:9D:72",
        CommunicationType.BTH
    );
    try {
      await bitalinoController.initialize();
      Utilities.showSnackBar(_scaffoldKey,"Initialized: BTH");
    } catch (Exception) {
      Utilities.showSnackBar(_scaffoldKey,"Initialized failed");
    }
  }
  Future<void> setupBitalinoConnection() async{
    isSetup = await bitalinoController.connect(
        onConnectionLost: () {
          Utilities.showSnackBar(_scaffoldKey,'Connection lost');
        });
    Utilities.showSnackBar(_scaffoldKey,"Connected: $isSetup");

  }
  Future<void> startBitalino({Frequency samplingRate,int numberOfSamples, })async{
    DateTime previousTime;
    bool started = false;


       previousTime = DateTime.now();
        started = await bitalinoController.start(
         [0,1],
         samplingRate,
         numberOfSamples: numberOfSamples, // For now this is a good number
         onDataAvailable: (frame) {
           if (data.length >= 300) data.removeAt(0); // data sample shown on screen
           if (data2.length >= 300) data2.removeAt(0);

           setState(() {
             data.add(SensorValue(previousTime,
                 frame.analog[0].toDouble()));
             data2.add(SensorValue(previousTime,
                 frame.analog[1].toDouble()));
             previousTime =
                 DateTime.fromMillisecondsSinceEpoch(
                     previousTime.millisecondsSinceEpoch +
                         1000 ~/ 10);
           });
         },
       );


  //   return started;
  }
  Future<bool> stopBitalino()async{
    bool stopped = await bitalinoController.stop();
    if(stopped)Utilities.showSnackBar(_scaffoldKey, "Bitalino Stopped");
  }

 
}
*/
import 'package:smart_cuff/Screens/Fatigue.dart';
import 'file:///C:/Users/Administrator/Desktop/smart_cuff/lib/Charts/chart.dart';
 import 'package:smart_cuff/HiveModel/emgSensorValue.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:bitalino/bitalino.dart';
import 'package:hive/hive.dart';


class EmgAnalyticsPage extends StatefulWidget {
  @override
  _EmgAnalyticsPageState createState() => _EmgAnalyticsPageState();
}

class _EmgAnalyticsPageState extends State<EmgAnalyticsPage> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BITalinoController bitalinoController;
  int sequence = 0;
  List<SensorValue> data = [];
  List<SensorValue> data2 = [];
  List<EmgSensorValue> dataRecords_bi = [];
  List<EmgSensorValue> dataRecords_tri = [];
  List<int> emgTemp = [];
  //DateTime previousTime;
  TextEditingController controller = TextEditingController();
  bool isSetup =false;
  bool isConnected;
  DateTime sessionTimestamp; /// Will be used to generate the key for the session-recording


  @override
  void initState()  {
    super.initState();
    initPlatformState();
    //setupBitalinoConnection();
    Future.delayed(const Duration(seconds: 1), () {
      setupBitalinoConnection();
    });
    Future.delayed(const Duration(seconds: 4), () {
      startBitalino();
    });
  }



  @override
  Widget build(BuildContext context) {
    // startBitalino();

    return MaterialApp(

      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('EMG Analytics',
              style: TextStyle(color: Colors.red[300])),
          backgroundColor: CupertinoColors.white,
          elevation: 0.5,

        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            RaisedButton(
              shape:RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  side: BorderSide(color: Colors.red)
              ) ,
              onPressed: () async { // sen
                await bitalinoController.stop();
                print(dataRecords_bi.isNotEmpty);
                dataRecords_bi.isNotEmpty ? await storeToRecordsBox('BicepsEmg_$sessionTimestamp', dataRecords_bi):null;
                dataRecords_tri.isNotEmpty ? await storeToRecordsBox('TricepsEmg_$sessionTimestamp', dataRecords_tri):null;

                //storeToRecordsBox('BicepsEmg_$sessionTimestamp', dataRecords_bi);
                //storeToRecordsBox('TricepsEmg_$sessionTimestamp', dataRecords_tri);
                storeToTempBox('emgForFatigue', emgTemp);
                dataRecords_tri = [];
                dataRecords_bi = [];
                emgTemp = [];

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Server()),
                );
              },
              child: Text('Fatigue Analysis'),

            ),
            Text(
              "       Biceps/Quadriceps Muscle Group",
              style: TextStyle(fontSize: 20,color: Colors.grey),
            ),
            SizedBox(
              height: 8,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Chart(data),
              ),
            ),
            SizedBox(
              height: 3,
            ),
            Text(
              "       Triceps/Hamstring Muscle Group",
              style: TextStyle(fontSize: 20,color: Colors.grey),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Chart(data2),
              ),
            ),

          ],

        ),
      ),
    );
  }

  _notify(dynamic text) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(
          text.toString(),
        ),
        duration: Duration(
          seconds: 1,
        ),
      ),
    );
  }
  Future<void> initPlatformState() async {
    bitalinoController = BITalinoController(
    "98:D3:21:FC:8B:72",
        CommunicationType.BTH
    );
    try {
      await bitalinoController.initialize();
      _notify("Initialized: BTH");
    } catch (Exception) {
      //  Utilities.showSnackBar(_scaffoldKey,"Initialized failed");
    }
  }
  Future<void> setupBitalinoConnection() async{
    isSetup = await bitalinoController.connect(
        onConnectionLost: () {
          _notify('Connection lost');
        });
    _notify ("Bitalino Connected: $isSetup");

  }
  Future<void> startBitalino() async{  //{Frequency samplingRate,int numberOfSamples}
    DateTime previousTime;
    bool started = false;
    await Hive.openBox('EmgReadings');
    await Hive.openBox('sessionRecord');
    sessionTimestamp = DateTime.now();

    previousTime = DateTime.now();
    /*if(!isSetup){
      setupBitalinoConnection().whenComplete(() => startBitalino());
    }*/
    started = await bitalinoController.start(
      [1,2],
      Frequency.HZ100,
      numberOfSamples: 250, // For now this is a good number
      onDataAvailable: (frame) {
        if (data.length >= 300) data.removeAt(0); // data sample shown on screen
        if (data2.length >= 300) data2.removeAt(0);

        /// 'data' and 'data2' are for charts
        /// 'dataRecords_bi' and 'dataRecords_tri' are to be stored in DB
        setState(() {
           data.add(SensorValue(previousTime,
              frame.analog[1].toDouble()));
           dataRecords_bi.add(EmgSensorValue(previousTime,
               frame.analog[1].toDouble()));
           emgTemp.add(frame.analog[1].toInt());

          data2.add(SensorValue(previousTime,
              frame.analog[2].toDouble()));
           dataRecords_bi.add(EmgSensorValue(previousTime,
               frame.analog[1].toDouble()));
          //print ("Pressureeeeeee: ${frame.analog[1]}");
          previousTime =
              DateTime.fromMillisecondsSinceEpoch(
                  previousTime.millisecondsSinceEpoch +
                      1000 ~/ 10);
        });
      },
    );

    _notify ("Bitalinoooo: $started");

  }
  Future<void> startBitalino2() async{  //{Frequency samplingRate,int numberOfSamples}
    DateTime previousTime;
    bool started = false;


    previousTime = DateTime.now();
    /*if(!isSetup){
      setupBitalinoConnection().whenComplete(() => startBitalino());
    }*/

    started = await bitalinoController.start(
      [0,1],
      Frequency.HZ100,
      numberOfSamples: 250, // For now this is a good number
      onDataAvailable: (frame) {
        // if (data.length >= 300) data.removeAt(0); // data sample shown on screen
        if (data2.length >= 300) data2.removeAt(0);

        setState(() {
          data.add(SensorValue(previousTime,
              frame.analog[0].toDouble()));
          data2.add(SensorValue(previousTime,
              frame.analog[1].toDouble()));
          print ("Pressureeeeeee: ${frame.analog[1]}");
          previousTime =
              DateTime.fromMillisecondsSinceEpoch(
                  previousTime.millisecondsSinceEpoch +
                      1000 ~/ 10);
        });
      },
    );


    _notify ("Bitalinoooo: $started");
    print("sssssssssssssssssssssssssss");
  }
  Future<bool> stopBitalino()async{
    bool stopped = await bitalinoController.stop();
    //if(stopped)Utilities.showSnackBar(_scaffoldKey, "Bitalino Stopped");
  }

  /// 'storeToRecordsBox' stores a record of the entire session in the sesssionRecord box
  /// 'SessionRecord' box holds a record of emg readings for later reference
  /// key is: 'BixepsEmg/TricepsEmg' + timeStamp (time at which session started)
  Future<void> storeToRecordsBox(String key, List<EmgSensorValue> data ) async {
    print('storingggggg');
    var recordsBox = await Hive.openBox('SessionRecord');
    await recordsBox.put(key, data);
  }

  /// 'storeToRecordsBox' stores a emg readings from an ongoing session in the EmgReadings box
  /// 'EmgReadings' box holds a temporary record of emg readings to pass-on for fatigue analysis
  /// key is: 'BixepsReadings/TricepsReadings'
  Future<void> storeToTempBox (String key, List<int> data) async{
    var tempBox = await Hive.openBox('EmgReadings');
    await tempBox.put(key, data);
  }


}