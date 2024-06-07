import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/utils/utils.dart';
import 'package:flutter/material.dart';

extension NumExt on num {
  Decimal get decimalize => Decimal.parse(toString());

  num plus(num other) {
    if (this is int && other is int) {
      return this + other;
    }
    return (decimalize + other.decimalize).toDouble();
  }

  num minus(num other) {
    if (this is int && other is int) {
      return this - other;
    }
    return (decimalize - other.decimalize).toDouble();
  }

  num multiply(num other) {
    if (this is int && other is int) {
      return this * other;
    }
    return (decimalize * other.decimalize).toDouble();
  }

  num divide(num other) {
    if (this is int && other is int) {
      return this / other;
    }
    return (decimalize / other.decimalize).toDouble();
  }
}

class AxisChartHelper {
  factory AxisChartHelper() {
    return _singleton;
  }

  AxisChartHelper._internal();

  static final _singleton = AxisChartHelper._internal();

  /// Iterates over an axis from [min] to [max].
  ///
  /// [interval] determines each step
  ///
  /// If [minIncluded] is true, it starts from [min] value,
  /// otherwise it starts from [min] + [interval]
  ///
  /// If [maxIncluded] is true, it ends at [max] value,
  /// otherwise it ends at [max] - [interval]
  Iterable<num> iterateThroughAxis({
    required num min,
    bool minIncluded = true,
    required num max,
    bool maxIncluded = true,
    required num baseLine,
    required num interval,
  }) sync* {
    final initialValue = Utils()
        .getBestInitialIntervalValue(min, max, interval, baseline: baseLine);
    var axisSeek = initialValue;
    final firstPositionOverlapsWithMin = axisSeek == min;
    if (!minIncluded && firstPositionOverlapsWithMin) {
      axisSeek += interval;
    }
    final diff = max - min;
    final count = diff ~/ interval;
    final lastPosition = initialValue.plus(count.multiply(interval));
    final lastPositionOverlapsWithMax = lastPosition == max;
    final end =
        !maxIncluded && lastPositionOverlapsWithMax ? max - interval : max;

    final epsilon = interval / 100000;
    if (minIncluded && !firstPositionOverlapsWithMin) {
      yield min;
    }
    while (axisSeek <= end + epsilon) {
      yield axisSeek;
      axisSeek = axisSeek.plus(interval);
    }
    if (maxIncluded && !lastPositionOverlapsWithMax) {
      yield max;
    }
  }

  /// Calculate translate offset to keep [SideTitle] child
  /// placed inside its corresponding axis.
  /// The offset will translate the child to the closest edge inside
  /// of the corresponding axis bounding box
  Offset calcFitInsideOffset({
    required AxisSide axisSide,
    required double? childSize,
    required double parentAxisSize,
    required double axisPosition,
    required double distanceFromEdge,
  }) {
    if (childSize == null) return Offset.zero;

    // Find title alignment along its axis
    final axisMid = parentAxisSize / 2;
    final mainAxisAlignment = (axisPosition - axisMid).isNegative
        ? MainAxisAlignment.start
        : MainAxisAlignment.end;

    // Find if child widget overflowed outside the chart
    late bool isOverflowed;
    if (mainAxisAlignment == MainAxisAlignment.start) {
      isOverflowed = (axisPosition - (childSize / 2)).isNegative;
    } else {
      isOverflowed = (axisPosition + (childSize / 2)) > parentAxisSize;
    }

    if (isOverflowed == false) return Offset.zero;

    // Calc offset if child overflowed
    late double offset;
    if (mainAxisAlignment == MainAxisAlignment.start) {
      offset = (childSize / 2) - axisPosition + distanceFromEdge;
    } else {
      offset =
          -(childSize / 2) + (parentAxisSize - axisPosition) - distanceFromEdge;
    }

    switch (axisSide) {
      case AxisSide.left:
      case AxisSide.right:
        return Offset(0, offset);
      case AxisSide.top:
      case AxisSide.bottom:
        return Offset(offset, 0);
    }
  }
}
