import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/pie_chart/pie_chart_renderer.dart';
import 'package:flutter/material.dart';

/// Renders a pie chart as a widget, using provided [PieChartData].
class PieChart extends ImplicitlyAnimatedWidget {
  /// [data] determines how the [PieChart] should be look like,
  /// when you make any change in the [PieChartData], it updates
  /// new values with animation, and duration is [swapAnimationDuration].
  /// also you can change the [swapAnimationCurve]
  /// which default is [Curves.linear].
  const PieChart(
    this.data, {
    super.key,
    Duration swapAnimationDuration = defaultDuration,
    Curve swapAnimationCurve = Curves.linear,
  }) : super(
          duration: swapAnimationDuration,
          curve: swapAnimationCurve,
        );

  /// Default duration to reuse externally.
  static const defaultDuration = Duration(milliseconds: 150);

  /// Determines how the [PieChart] should be look like.
  final PieChartData data;

  /// Creates a [_PieChartState]
  @override
  _PieChartState createState() => _PieChartState();
}

class _PieChartState extends AnimatedWidgetBaseState<PieChart> {
  /// We handle under the hood animations (implicit animations) via this tween,
  /// it lerps between the old [PieChartData] to the new one.
  PieChartDataTween? _pieChartDataTween;

  BaseTouchCallback<PieTouchResponse>? _providedTouchCallback;

  PieTouchResponse? _touchResponse;

  @override
  void initState() {
    /// Make sure that [_widgetsPositionHandler] is updated.
    _ambiguate(WidgetsBinding.instance)!.addPostFrameCallback((timeStamp) {
      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  /// This allows a value of type T or T? to be treated as a value of type T?.
  ///
  /// We use this so that APIs that have become non-nullable can still be used
  /// with `!` and `?` to support older versions of the API as well.
  T? _ambiguate<T>(T? value) => value;

  @override
  Widget build(BuildContext context) {
    final showingData = _getData();

    return PieChartLeaf(
      targetData: showingData,
      data: _pieChartDataTween!.evaluate(animation),
      touchResponse: _touchResponse,
    );
  }

  /// if builtIn touches are enabled, we should recreate our [pieChartData]
  /// to handle built in touches
  PieChartData _getData() {
    final newData = widget.data;

    final pieTouchData = newData.pieTouchData;
    if (pieTouchData.enabled && pieTouchData.handleBuiltInTouches) {
      _providedTouchCallback = pieTouchData.touchCallback;
      return newData.copyWith(
        pieTouchData:
            newData.pieTouchData.copyWith(touchCallback: _handleBuiltInTouch),
      );
    }
    return newData;
  }

  void _handleBuiltInTouch(
    FlTouchEvent event,
    PieTouchResponse? touchResponse,
  ) {
    if (!mounted) {
      return;
    }
    _providedTouchCallback?.call(event, touchResponse);

    if (!event.isInterestedForInteractions ||
        touchResponse == null ||
        touchResponse.touchedSection == null) {
      setState(() {
        _touchResponse = null;
      });
      return;
    }
    setState(() {
      _touchResponse = touchResponse;
    });
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _pieChartDataTween = visitor(
      _pieChartDataTween,
      widget.data,
      (dynamic value) =>
          PieChartDataTween(begin: value as PieChartData, end: widget.data),
    ) as PieChartDataTween?;
  }
}

/// Positions the badge widgets on their respective sections.
class BadgeWidgetsDelegate extends MultiChildLayoutDelegate {
  BadgeWidgetsDelegate({
    required this.badgeWidgetsCount,
    required this.badgeWidgetsOffsets,
  });

  final int badgeWidgetsCount;
  final Map<int, Offset> badgeWidgetsOffsets;

  @override
  void performLayout(Size size) {
    for (var index = 0; index < badgeWidgetsCount; index++) {
      final key = badgeWidgetsOffsets.keys.elementAt(index);

      final finalSize = layoutChild(
        key,
        BoxConstraints(
          maxWidth: size.width,
          maxHeight: size.height,
        ),
      );

      positionChild(
        key,
        Offset(
          badgeWidgetsOffsets[key]!.dx - (finalSize.width / 2),
          badgeWidgetsOffsets[key]!.dy - (finalSize.height / 2),
        ),
      );
    }
  }

  @override
  bool shouldRelayout(BadgeWidgetsDelegate oldDelegate) {
    return oldDelegate.badgeWidgetsOffsets != badgeWidgetsOffsets;
  }
}
