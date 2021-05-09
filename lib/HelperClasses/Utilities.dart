import 'package:flutter/material.dart';

class Utilities{
  static void showSnackBar(GlobalKey<ScaffoldState> scaffoldKey, String msg){
scaffoldKey.currentState.showSnackBar(SnackBar(
  content: Text(msg),
  duration: Duration(seconds: 2),
));

  }

}