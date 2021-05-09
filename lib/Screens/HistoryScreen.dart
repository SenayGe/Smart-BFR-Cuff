import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_cuff/Screens/VisualizeRecord.dart';

class HistoryScreen extends StatefulWidget{
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState  extends State<HistoryScreen>{


  @override
  void initState() {
    super.initState();
  }




  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    var emgRecordsBox = Hive.box('SessionRecord');

    return Scaffold(
      appBar: AppBar(
        title: Text('Session Records',
            style: TextStyle(color: Colors.red[300])),
        centerTitle: true,
        backgroundColor: CupertinoColors.white,
        elevation: 0.5,
      ),
      body: ListView.builder(
          itemCount: emgRecordsBox.length,
          itemBuilder: (context, index){

            return Card(
              child: ListTile(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> VisualizeRecordScreen(keyIndex: index)));
                },
                title: Text('${emgRecordsBox.keyAt(index)}'),
              ),
            );
          },

      ),
    );
  }

}

