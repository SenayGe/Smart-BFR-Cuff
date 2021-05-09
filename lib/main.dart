import 'package:flutter/material.dart';
import 'package:smart_cuff/BottomNavigationItems/WorkoutTabbedPage.dart';
import 'package:smart_cuff/Cuffinflation.dart';
import 'package:smart_cuff/DiscoveryPage.dart';
import 'package:smart_cuff/Screens/Fatigue.dart';
import 'package:smart_cuff/Screens/HistoryScreen.dart';
import 'package:smart_cuff/Screens/PairingScreen.dart';
import 'package:smart_cuff/Screens/PairingScreen.dart';
import 'package:smart_cuff/Tabs/DashBoard.dart';
import 'package:smart_cuff/Tabs/EmgPage.dart';
import 'HiveModel/emgSensorValue.dart';
import 'SmartWatch.dart';
import 'package:smart_cuff/Screens/LopCalibrationScreen.dart';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDirectory =  await getApplicationDocumentsDirectory();
  await Hive.init(appDocDirectory.path);
  Hive.registerAdapter(EmgSensorValueAdapter());
  await Hive.openBox('SessionRecord');
  runApp(new SmartCuffApplication());
}

class SmartCuffApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        home: PairingScreen(),
    );
  }
}


