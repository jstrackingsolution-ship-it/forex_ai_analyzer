import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Chati rahisi ya mstari kwa viashiria kama RSI (yenye overbought/oversold zones)
class RsiChart extends StatelessWidget {
  final List<double?> values;
  final double height;

  const RsiChart({super.key, required this.values, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i] != null) spots.add(FlSpot(i.toDouble(), values[i]!));
    }

    if (spots.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('RSI: Data haitoshi')));
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 50,
                getTitlesWidget: (v, meta) => Text(
                  v.toInt().toString(),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(y: 70, color: Colors.red.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
            HorizontalLine(y: 30, color: Colors.green.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
          ]),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF448AFF),
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chati ya MACD - mistari miwili (MACD & Signal) pamoja na histogram
class MacdChart extends StatelessWidget {
  final List<double?> macdLine;
  final List<double?> signalLine;
  final List<double?> histogram;
  final double height;

  const MacdChart({
    super.key,
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final macdSpots = <FlSpot>[];
    final signalSpots = <FlSpot>[];
    final barGroups = <BarChartGroupData>[];

    double minY = 0, maxY = 0;

    for (int i = 0; i < macdLine.length; i++) {
      if (macdLine[i] != null) {
        macdSpots.add(FlSpot(i.toDouble(), macdLine[i]!));
        if (macdLine[i]! < minY) minY = macdLine[i]!;
        if (macdLine[i]! > maxY) maxY = macdLine[i]!;
      }
      if (signalLine[i] != null) {
        signalSpots.add(FlSpot(i.toDouble(), signalLine[i]!));
      }
      if (histogram[i] != null) {
        barGroups.add(BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: histogram[i]!,
            color: histogram[i]! >= 0 ? const Color(0xFF00C853) : const Color(0xFFD50000),
            width: 2,
          )
        ]));
      }
    }

    if (macdSpots.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('MACD: Data haitoshi')));
    }

    final padding = (maxY - minY).abs() * 0.2 + 0.0001;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          BarChart(
            BarChartData(
              minY: minY - padding,
              maxY: maxY + padding,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              barGroups: barGroups,
            ),
          ),
          LineChart(
            LineChartData(
              minY: minY - padding,
              maxY: maxY + padding,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, meta) => Text(
                      v.toStringAsFixed(4),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: macdSpots,
                  isCurved: false,
                  color: const Color(0xFF448AFF),
                  barWidth: 1.8,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: signalSpots,
                  isCurved: false,
                  color: const Color(0xFFFFAB40),
                  barWidth: 1.8,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
