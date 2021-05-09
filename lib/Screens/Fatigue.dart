import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
//import 'package:fit_kit/fit_kit.dart';
//import 'package:fit_kit/fit_kit.dart';

import 'package:smart_cuff/Screens/HistoryScreen.dart';
import 'file:///C:/Users/Administrator/Desktop/smart_cuff/lib/Charts/chartFatigue.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'API.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
//import 'package:fitkit_demo/fLchart.dart';
//import 'package:fl_chart/fl_chart.dart';
import 'package:smart_cuff/Database/databaseHelper.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Server extends StatefulWidget {
  @override
  _ServerState createState() => _ServerState();
}
class _ServerState extends State<Server> {
  String url;
  List name= [1,1,1];
  List<dynamic> freqAxis=[];
  List<dynamic> timeAxis=[];
  List<FatigueValue> data=[];
  //List<FlSpot> data2=[FlSpot(0, 0)];
  int reps;
  bool isDataPosted = false;
  var mnFreqJson;

  List<int> emg=[];
  List<int> emg2=[];
  List<int> hiveTest = []; // For testin the hive DB
  List<int> hiveTest2 = [];
  List<Map> emgDB;

  @override
  void initState()  {
    super.initState();
    getFileLines();

  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Fatigue Analytics',
              style: TextStyle(color: Colors.red[300])),
          backgroundColor: CupertinoColors.white,
          elevation: 0.5,
        ),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
              children:[ RaisedButton(
                shape:RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.red)
                ) ,
                onPressed: () async { // sen

                  print("doneeee");
                  data=[];

                  /// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ HIVE DB IMPLEMENTATION ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                  print(emg.length);
                  var emgBox = Hive.box('EmgReadings');
                  emg2 = emgBox.get('emgForFatigue');

                  print("sssssssssssss: ${hiveTest2.length}");
                  print(emgBox.keys);
                  print(DateTime.now());
                  /// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ end of HIVE ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

                  setState(() {
                    isDataPosted = true;
                  });
                  final url = 'https://esmartcuff.pythonanywhere.com/';

                  final response= await http.post(url, body: json.encode({'Emg': emg2}));

                  final response2=await http.get(url);


                  final decoded = json.decode(response2.body) as Map<String, dynamic>;

                  setState(() {
                    freqAxis = decoded['MedianFreq']; //decoded['MedianFreq'].cast<double>()
                    timeAxis = decoded['MedianTime'];
                    reps=decoded['Reps'];
                    for (int i=0; i < freqAxis.length; i++){
                      data.add(new FatigueValue(timeAxis[i].toDouble(), freqAxis[i].toDouble()));
                    }

                    //print (data.length);
                    //print("dataaaaaaaaaaaaaaaaaa: ${data[0].value}");
                    //print("Repssssssssssssssssssssss: ${data[(data.length-1)].time}");

                    isDataPosted = false;
                  });
                },
                child: Text('send'),

              ),
              SizedBox(
                width: 100,
              ),
              RaisedButton(
                  shape:RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: Colors.red)
                  ) ,
                  onPressed: () async{
                    var emgRecordsBox = Hive.box('sessionRecord');
                    //await emgRecordsBox.clear();
                    print("History Record:  ${emgRecordsBox.keys}");
                    String k= emgRecordsBox.keyAt(0);
                    print('elements:   ${emgRecordsBox.get(k).length}');

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()),
                    );
                  },
                child: Text('SAVE'),
              )
              ]// raisedButton
              ),
              SizedBox(
                height: 15,
              ),

              Text(
                !isDataPosted ? "" : "Waiting...",
                style: TextStyle(fontSize: 24,color: Colors.grey[800]),
              ),
              SizedBox(
                height: 15,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child:   ChartFatigue(data),             //ChartFatigue(data),
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }

  Future<void> getFileLines() async {
    final data = await rootBundle.load('assets/emg.txt');
    final directory = (await getTemporaryDirectory()).path;
    final file = await writeToFile(data, '$directory/emg.txt');
    await file.readAsLines().then((lines){
      emg = lines.map(int.parse).toList();
    });
    for (int i = 0; i< 20; i++){
      hiveTest.add(emg[i]); // INSERTING TO DATABASE
    }
  }

  Future<File> writeToFile(ByteData data, String path) {
    return File(path).writeAsBytes(data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    ));
  }

  Future<void> saveToDatabase() async{
    // ************ Store readings in a database *************
    int emg_length = emg.length;
    print("the length of emg data is::::::::: $emg_length");
    for (int i = 0; i< emg.length; i++){
      await DatabaseHelper.instance.insert("1",emg[i],0); // INSERTING TO DATABASE
    }
  } // SQL Database

  /// ********* SQL DATABASE IMPLEMENTATION (TESTING)****************************
  //emgDB= await DatabaseHelper.instance.getEmgReading();
  //emg2 = emgDB['bicepsCH'];
  //String rawjson = jsonEncode(data);
  // Reading from file
  /*File file = new File('/assets/emg.txt');
                  await file.readAsLines().then((lines){
                    emg= lines.map(int.parse).toList();
                  }
                  );*/
  /*print("sssssssssssssss: ${emgDB[0]}" );
                  print("sssssssssssssss: ${emgDB[10]['bicepsCH']}" );
                  print(emgDB.length);*/
  /*for(int i=0;i<emgDB.length;i++) async{
                    await emg2.add(emgDB[i]['bicepsCH']);
                  }*/
  //await emgDB.forEach((Map i){emg2.add(i['bicepsCH']);});
  /// ************************* END OF SQL *****************************************
}
