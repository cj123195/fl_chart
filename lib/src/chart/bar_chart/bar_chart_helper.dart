import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:fl_chart/src/chart/bar_chart/bar_chart_data.dart';
import 'package:fl_chart/src/utils/list_wrapper.dart';

/// Contains anything that helps BarChart works
class BarChartHelper {
  /// Contains List of cached results, base on [List<BarChartGroupData>]
  ///
  /// We use it to prevent redundant calculations
  final Map<ListWrapper<BarChartGroupData>, BarChartMinMaxAxisValues>
      _cachedResults = {};

  /// Calculates minY, and maxY based on [barGroups],
  /// returns cached values, to prevent redundant calculations.
  BarChartMinMaxAxisValues calculateMaxAxisValues(
    List<BarChartGroupData> barGroups,
  ) {
    if (barGroups.isEmpty) {
      return BarChartMinMaxAxisValues(0, 0);
    }

    final listWrapper = barGroups.toWrapperClass();

    if (_cachedResults.containsKey(listWrapper)) {
      return _cachedResults[listWrapper]!.copyWith(readFromCache: true);
    }

    final BarChartGroupData barGroup;
    try {
      barGroup = barGroups.firstWhere((element) => element.barRods.isNotEmpty);
    } catch (e) {
      // There is no barChartGroupData with at least one barRod
      return BarChartMinMaxAxisValues(0, 0);
    }

    var maxY = max(barGroup.barRods[0].from, barGroup.barRods[0].to);
    var minY = min(barGroup.barRods[0].from, barGroup.barRods[0].to);

    for (var i = 0; i < barGroups.length; i++) {
      final barGroup = barGroups[i];
      for (var j = 0; j < barGroup.barRods.length; j++) {
        final rod = barGroup.barRods[j];

        maxY = max(maxY, rod.from);
        minY = min(minY, rod.from);

        maxY = max(maxY, rod.to);
        minY = min(minY, rod.to);

        if (rod.backDrawRodData.show) {
          maxY = max(maxY, rod.backDrawRodData.from);
          minY = min(minY, rod.backDrawRodData.from);
          maxY = max(maxY, rod.backDrawRodData.to);
          minY = min(minY, rod.backDrawRodData.to);
        }
      }
    }

    final result = BarChartMinMaxAxisValues(minY, maxY);
    _cachedResults[listWrapper] = result;
    return result;
  }
}

/// Holds minY, and maxY for use in [BarChartData]
class BarChartMinMaxAxisValues with EquatableMixin {
  BarChartMinMaxAxisValues(
    this.minvalue,
    this.maxvalue, {
    this.readFromCache = false,
  });

  final num minvalue;
  final num maxvalue;
  final bool readFromCache;

  @override
  List<Object?> get props => [minvalue, maxvalue, readFromCache];

  BarChartMinMaxAxisValues copyWith({
    double? minvalue,
    double? maxvalue,
    bool? readFromCache,
  }) {
    return BarChartMinMaxAxisValues(
      minvalue ?? this.minvalue,
      maxvalue ?? this.maxvalue,
      readFromCache: readFromCache ?? this.readFromCache,
    );
  }
}
