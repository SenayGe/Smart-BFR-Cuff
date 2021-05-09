import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class Chart extends StatelessWidget {
  final List<SensorValue> _data;
  int upper=600;

  Chart(this._data);

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart([
      charts.Series<SensorValue, DateTime>(
        id: 'Values',
        colorFn: (_, __) => charts.MaterialPalette.gray.shade400,   // green.shadeDefault
        domainFn: (SensorValue values, _) => values.time,
        measureFn: (SensorValue values, _) => ((values.value)-500).abs(),

        data: _data,
      )
    ],
        animate: false,
        primaryMeasureAxis: charts.NumericAxisSpec(
          tickProviderSpec:
          charts.BasicNumericTickProviderSpec(zeroBound: false),
          viewport: new charts.NumericExtents(0, 600),
        ),
        domainAxis: new charts.DateTimeAxisSpec(
            renderSpec: new charts.NoneRenderSpec()));
  }
}

 Widget chart(List<SensorValue> _data){
  return new charts.TimeSeriesChart([
    charts.Series<SensorValue, DateTime>(
      id: 'Values',
      colorFn: (_, __) => charts.MaterialPalette.gray.shade400,   // green.shadeDefault
      domainFn: (SensorValue values, _) => values.time,
      measureFn: (SensorValue values, _) => ((values.value)-500).abs(),

      data: _data,
    )
  ],
      animate: false,
      primaryMeasureAxis: charts.NumericAxisSpec(
        tickProviderSpec:
        charts.BasicNumericTickProviderSpec(zeroBound: false),
        viewport: new charts.NumericExtents(0, 600),
      ),
      domainAxis: new charts.DateTimeAxisSpec(
          renderSpec: new charts.NoneRenderSpec()));

 }
class SensorValue {
  final DateTime time;
  final double value;

  SensorValue(this.time, this.value);
}