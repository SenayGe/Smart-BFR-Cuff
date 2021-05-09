import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_cuff/Charts/chartHistory.dart';
import 'package:smart_cuff/HiveModel/emgSensorValue.dart';

class VisualizeRecordScreen extends StatefulWidget {
  final int keyIndex;

  VisualizeRecordScreen({this.keyIndex});
  @override
  _VisualizeRecordScreenState createState() => _VisualizeRecordScreenState();
}

class _VisualizeRecordScreenState extends State<VisualizeRecordScreen> {
  int s;
  List<dynamic> data = [];
  List<dynamic> dataTemp = [];
  var emgRecordBox;
  int keyIndex;

  @override
  void initState(){
    keyIndex = widget.keyIndex;
    emgRecordBox = Hive.box('SessionRecord');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualizer',
            style: TextStyle(color: Colors.red[300])),
        backgroundColor: CupertinoColors.white,
        elevation: 0.5,) ,
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RaisedButton(
              shape:RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  side: BorderSide(color: Colors.red)
              ) ,
              onPressed: () async{
                String identifier;
                identifier = emgRecordBox.keyAt(keyIndex);
                data = emgRecordBox.get(identifier);

              },
              child: Text('PLAY'),
            ),
            SizedBox(
              height: 10,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child:   ChartHistory(data),             //ChartFatigue(data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
