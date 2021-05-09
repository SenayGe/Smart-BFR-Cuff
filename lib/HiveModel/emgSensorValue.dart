

import 'package:hive/hive.dart';

part 'emgSensorValue.g.dart';
@HiveType(typeId: 0)
class EmgSensorValue{

  @HiveField(0)
  final DateTime time;

  @HiveField(1)
  final double value;

  EmgSensorValue(this.time, this.value);

}