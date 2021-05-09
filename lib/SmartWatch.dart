import 'dart:async';

import 'package:fit_kit/fit_kit.dart';
import 'package:fit_kit/fit_kit.dart';
import 'package:flutter/material.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String result = '';
  Map<DataType, List<FitData>> results = Map();
  bool permissions=false;
  DateTime lastRead;
  FitData _hr;


  @override
  void initState() {
   requestWatchPermission();
    if(!permissions){
     requestWatchPermission();
    }
    super.initState();

  }

  Future<void> requestWatchPermission() async{
    permissions = await FitKit.requestPermissions(DataType.values);
    print("Watch Permission provided: $permissions");
  }

  Future<void> read() async {  // Read HR from GFit

    _hr = await FitKit.readLast(DataType.HEART_RATE);
    setState(() {});
  }

  Future<void> revokePermissions() async {
    results.clear();

    try {
      await FitKit.revokePermissions();
      permissions = await FitKit.hasPermissions(DataType.values);
      result = 'revokePermissions: success';
    } catch (e) {
      result = 'revokePermissions: $e';
    }

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {

    Timer.periodic(Duration(seconds: 5), (Timer timer)  {
      read();
    });


    List<dynamic>items =
    results.entries.expand((entry) => [entry.key, ...entry.value]).toList();


    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('FitKit Example'),
        ),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              Text(
                "${_hr!=null?_hr.value:"--"}",
                style: TextStyle(fontSize: 24,color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateToString(DateTime dateTime) {
    if (dateTime == null) {
      return 'null';
    }

    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }



}
/*import 'dart:async';

import 'package:fit_kit/fit_kit.dart';
import 'package:flutter/material.dart';

class SmartWatchState {
  String result = '';
  Map<DataType, List<FitData>> results = Map();
  bool permissions=false;
  DateTime lastRead;
  FitData _hr;


  Future<void> requestWatchPermission() async {
    permissions = await FitKit.requestPermissions(DataType.values);
    if(!permissions){
      permissions = await FitKit.requestPermissions(DataType.values);
    }
    }

  Future<void> read() async {  // Read HR from GFit
    if(permissions){
      FitKit.readLast(DataType.HEART_RATE).then((FitData fitkitResponse) => _hr = fitkitResponse);
    }
  }

*//*  Future<void> revokePermissions() async {
    results.clear();
    try {
      await FitKit.revokePermissions();
      permissions = await FitKit.hasPermissions(DataType.values);
      result = 'revokePermissions: success';
    } catch (e) {
      result = 'revokePermissions: $e';
    }

  }*//*

  void fetchHeartRateData() {
    Timer.periodic(Duration(seconds: 5), (Timer timer)  {
      read();
    });
  }
  get heartRate(){
    return _hr.value;
  }

}*/
