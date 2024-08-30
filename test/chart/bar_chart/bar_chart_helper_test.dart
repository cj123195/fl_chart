import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/bar_chart/bar_chart_helper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_pool.dart';

void main() {
  group('Check caching of BarChartHelper.calculateMaxAxisValues', () {
    test('Test read from cache1', () {
      final barChartHelper = BarChartHelper();
      final barGroups1 = [barChartGroupData1];
      final result1 = barChartHelper.calculateMaxAxisValues(barGroups1);

      final barGroups2 = [barChartGroupData2];
      final result2 = barChartHelper.calculateMaxAxisValues(barGroups2);
      expect(result1.readFromCache, false);
      expect(result2.readFromCache, false);
    });

    test('Test read from cache2', () {
      final barChartHelper = BarChartHelper();
      final barGroups = [barChartGroupData1, barChartGroupData2];
      final result1 = barChartHelper.calculateMaxAxisValues(barGroups);
      final result2 = barChartHelper.calculateMaxAxisValues(barGroups);
      expect(result1.readFromCache, false);
      expect(result2.readFromCache, true);
    });

    test('Test validity 1', () {
      final barChartHelper = BarChartHelper();
      final barGroups = [barChartGroupData1, barChartGroupData2];
      final result = barChartHelper.calculateMaxAxisValues(barGroups);
      expect(result.minvalue, 0);
      expect(result.maxvalue, 1132);
    });

    test('Test validity 2', () {
      final barChartHelper = BarChartHelper();
      final barGroups = [
        barChartGroupData1.copyWith(
          barRods: [
            BarChartRodData(to: -10),
            BarChartRodData(to: -40),
            BarChartRodData(to: 0),
            BarChartRodData(to: 10),
            BarChartRodData(to: 5),
          ],
        ),
      ];
      final result = barChartHelper.calculateMaxAxisValues(barGroups);
      expect(result.minvalue, -40);
      expect(result.maxvalue, 10);
    });

    test('Test validity 3', () {
      final barChartHelper = BarChartHelper();
      final barGroups = [
        barChartGroupData1.copyWith(barRods: []),
      ];
      final result = barChartHelper.calculateMaxAxisValues(barGroups);
      expect(result.minvalue, 0);
      expect(result.maxvalue, 0);
    });

    test('Test validity 4', () {
      final barChartHelper = BarChartHelper();
      final barGroups = [
        barChartGroupData1.copyWith(
          barRods: [
            BarChartRodData(from: 0, to: -10),
            BarChartRodData(from: -10, to: -40),
            BarChartRodData(to: 0),
            BarChartRodData(to: 10),
            BarChartRodData(to: 5),
            BarChartRodData(from: 10, to: -50),
            BarChartRodData(from: 39, to: -50),
          ],
        ),
      ];
      final result = barChartHelper.calculateMaxAxisValues(barGroups);
      expect(result.minvalue, -50);
      expect(result.maxvalue, 39);
    });

    test('Test equality', () {
      final barChartHelper = BarChartHelper();
      final barGroups = [barChartGroupData1, barChartGroupData2];
      final result1 = barChartHelper.calculateMaxAxisValues(barGroups);
      final result2 = barChartHelper.calculateMaxAxisValues(barGroups).copyWith(
            readFromCache: false,
          );
      expect(result1, result2);
    });

    test('Test equality2', () {
      final barChartHelper = BarChartHelper();
      final barGroups = [barChartGroupData1, barChartGroupData2];
      final result1 = barChartHelper
          .calculateMaxAxisValues(barGroups)
          .copyWith(readFromCache: true);
      final result2 = result1.copyWith(readFromCache: false);
      expect(result1 != result2, true);
    });

    test('Test BarChartMinMaxAxisValues class', () {
      final result1 = BarChartMinMaxAxisValues(0, 10)
          .copyWith(minvalue: 1, maxvalue: 11, readFromCache: true);
      final result2 = BarChartMinMaxAxisValues(1, 11, readFromCache: true);
      expect(result1, result2);
    });

    test('Test calculateMaxAxisValues with all positive values', () {
      final barChartHelper = BarChartHelper();
      final barGroups = [
        barChartGroupData1.copyWith(
          barRods: barChartGroupData1.barRods
              .map(
                (rod) => rod.copyWith(
                  from: 5,
                  backDrawRodData: BackgroundBarChartRodData(show: false),
                ),
              )
              .toList(),
        ),
        barChartGroupData2.copyWith(
          barRods: barChartGroupData2.barRods
              .map(
                (rod) => rod.copyWith(
                  from: 8,
                  backDrawRodData: BackgroundBarChartRodData(show: false),
                ),
              )
              .toList(),
        ),
      ];
      final result1 = barChartHelper.calculateMaxAxisValues(barGroups);
      expect(result1.minvalue, 5);
    });

    test('Test calculateMaxAxisValues with all negative values', () {
      final barChartHelper = BarChartHelper();
      final barGroups = [
        barChartGroupData1.copyWith(
          barRods: barChartGroupData1.barRods
              .map((rod) => rod.copyWith(from: -5))
              .toList(),
        ),
        barChartGroupData2.copyWith(
          barRods: barChartGroupData2.barRods
              .map((rod) => rod.copyWith(from: -8))
              .toList(),
        ),
      ];
      final result1 = barChartHelper.calculateMaxAxisValues(barGroups);
      expect(result1.minvalue, -8);
    });
  });
}
