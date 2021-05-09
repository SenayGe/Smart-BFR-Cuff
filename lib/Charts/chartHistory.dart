import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:smart_cuff/HiveModel/emgSensorValue.dart';

class ChartHistory extends StatelessWidget {
  final List<dynamic> _data;
  int upper=600;

  ChartHistory(this._data);

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart([
      charts.Series<dynamic, DateTime>(
        id: 'Values',
        colorFn: (_, __) => charts.MaterialPalette.gray.shade400,   // green.shadeDefault
        domainFn: (dynamic values, _) => values.time,
        measureFn: (dynamic values, _) => ((values.value)-500).abs(),

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

Widget chart(List<EmgSensorValue> _data){
  return new charts.TimeSeriesChart([
    charts.Series<dynamic, DateTime>(
      id: 'Values',
      colorFn: (_, __) => charts.MaterialPalette.gray.shade400,   // green.shadeDefault
      domainFn: (dynamic values, _) => values.time,
      measureFn: (dynamic values, _) => ((values.value)-500).abs(),

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
