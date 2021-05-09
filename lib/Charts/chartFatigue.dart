import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class ChartFatigue extends StatelessWidget {
  final List<FatigueValue> _data;
  //int upper=600;

  ChartFatigue(this._data);

  _getSeriesData(){
    List<charts.Series<FatigueValue, double>> series=[
      charts.Series(
        id: 'Values',
        data: _data,
        colorFn: (_, __) => charts.MaterialPalette.gray.shade400,   // green.shadeDefault
        domainFn: (FatigueValue values, _) => values.time,
        measureFn: (FatigueValue values, _) => (values.value),
      )
    ];
    return series;
  }

  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(_getSeriesData(), animate: true,primaryMeasureAxis: charts.NumericAxisSpec(
        tickProviderSpec:
        charts.BasicNumericTickProviderSpec(zeroBound: false)));
  }
}

class FatigueValue {
  final double time;
  final double value;

  FatigueValue(this.time, this.value);
}

/*
animate: true,
primaryMeasureAxis: charts.NumericAxisSpec(
tickProviderSpec:
charts.BasicNumericTickProviderSpec(zeroBound: false),
//viewport: new charts.NumericExtents(0, 600),
),
domainAxis: new charts.DateTimeAxisSpec(
renderSpec: new charts.NoneRenderSpec()));*/