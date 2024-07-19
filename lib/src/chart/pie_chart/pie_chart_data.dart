import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/utils/lerp.dart';
import 'package:flutter/material.dart';

/// [PieChart] needs this class to render itself.
///
/// It holds data needed to draw a pie chart,
/// including pie sections, colors, ...
class PieChartData extends BaseChartData with EquatableMixin {
  /// [PieChart] draws some [sections] in a circle,
  /// and applies free space with radius [centerSpaceRadius],
  /// and color [centerSpaceColor] in the center of the circle,
  /// if you don't want it, set [centerSpaceRadius] to zero.
  ///
  /// It draws [sections] from zero degree (right side of the circle) clockwise,
  /// you can change the starting point, by changing [startDegreeOffset]
  /// (in degrees).
  ///
  /// You can define a gap between [sections] by setting [sectionsSpace].
  ///
  /// You can modify [pieTouchData] to customize touch behaviors and responses.
  PieChartData({
    List<PieChartSectionData>? sections,
    double? centerSpaceRadiusRatio,
    Color? centerSpaceColor,
    double? sectionsSpace,
    double? startDegreeOffset,
    PieTouchData? pieTouchData,
    FlBorderData? borderData,
    this.centerSpaceBorder,
    this.sectionsBorder,
    bool? titleSunbeamLayout,
    bool showZeroValue = true,
    bool? showZeroTitle,
    this.strokeCapRoundMode,
  })  : assert(
          sectionsBorder == null ||
              (sectionsSpace == 0 &&
                  (sections == null ||
                      sections.isEmpty ||
                      sections.every(
                        (s) => s.radiusRatio == sections[0].radiusRatio,
                      ))),
          'When the border is not null, sectionsSpace must be 0 and the radius '
          'of all sections must be equal.',
        ),
        assert(
          centerSpaceRadiusRatio == null ||
              (centerSpaceRadiusRatio >= 0 && centerSpaceRadiusRatio <= 1),
        ),
        sections = (showZeroValue
                ? sections
                : sections?.where((section) => section.value != 0).toList()) ??
            const [],
        centerSpaceRadiusRatio = centerSpaceRadiusRatio ?? 0,
        centerSpaceColor = centerSpaceColor ?? Colors.transparent,
        sectionsSpace = sectionsSpace ?? 2,
        startDegreeOffset = startDegreeOffset ?? 0,
        pieTouchData = pieTouchData ?? PieTouchData(),
        titleSunbeamLayout = titleSunbeamLayout ?? false,
        showZeroTitle = showZeroTitle ?? false,
        super(
          borderData: borderData ?? FlBorderData(show: false),
          touchData: pieTouchData ?? PieTouchData(),
        );

  /// Defines showing sections of the [PieChart].
  final List<PieChartSectionData> sections;

  /// Radius of free space in center of the circle.
  final double centerSpaceRadiusRatio;

  /// Color of free space in center of the circle.
  final Color centerSpaceColor;

  /// Border of free space in center of the circle.
  final BorderSide? centerSpaceBorder;

  /// Border of all [sections]
  final BorderSide? sectionsBorder;

  /// Defines gap between sections.
  ///
  /// Does not work on html-renderer,
  /// https://github.com/imaNNeo/fl_chart/issues/955
  final double sectionsSpace;

  /// [PieChart] draws [sections] from zero degree (right side of the circle)
  /// clockwise.
  final double startDegreeOffset;

  /// Handles touch behaviors and responses.
  final PieTouchData pieTouchData;

  /// Whether to rotate the titles on each section of the chart
  final bool titleSunbeamLayout;

  /// Whether to show the title with a value of 0 when [sumValue] is not 0
  ///
  /// Default to false.
  final bool showZeroTitle;

  /// Determine how to stroke the border of each section when center space radius
  /// is not zero.
  final PieStrokeCapRoundMode? strokeCapRoundMode;

  /// We hold this value to determine weight of each [PieChartSectionData.value].
  num get sumValue => sections
      .map((data) => data.value)
      .reduce((first, second) => first + second);

  /// Copies current [PieChartData] to a new [PieChartData],
  /// and replaces provided values.
  PieChartData copyWith({
    List<PieChartSectionData>? sections,
    double? centerSpaceRadiusRatio,
    Color? centerSpaceColor,
    double? sectionsSpace,
    double? startDegreeOffset,
    PieTouchData? pieTouchData,
    FlBorderData? borderData,
    bool? titleSunbeamLayout,
    bool? showZeroTitle,
    PieStrokeCapRoundMode? strokeCapRoundMode,
    List<int>? showingTooltipIndicators,
    BorderSide? centerSpaceBorder,
    BorderSide? sectionsBorder,
  }) {
    return PieChartData(
      sections: sections ?? this.sections,
      centerSpaceRadiusRatio:
          centerSpaceRadiusRatio ?? this.centerSpaceRadiusRatio,
      centerSpaceColor: centerSpaceColor ?? this.centerSpaceColor,
      sectionsSpace: sectionsSpace ?? this.sectionsSpace,
      startDegreeOffset: startDegreeOffset ?? this.startDegreeOffset,
      pieTouchData: pieTouchData ?? this.pieTouchData,
      borderData: borderData ?? this.borderData,
      titleSunbeamLayout: titleSunbeamLayout ?? this.titleSunbeamLayout,
      showZeroTitle: showZeroTitle ?? this.showZeroTitle,
      strokeCapRoundMode: strokeCapRoundMode ?? this.strokeCapRoundMode,
      centerSpaceBorder: centerSpaceBorder ?? this.centerSpaceBorder,
      sectionsBorder: sectionsBorder ?? this.sectionsBorder,
    );
  }

  /// Lerps a [BaseChartData] based on [t] value, check [Tween.lerp].
  @override
  PieChartData lerp(BaseChartData a, BaseChartData b, double t) {
    if (a is PieChartData && b is PieChartData) {
      return PieChartData(
        borderData: FlBorderData.lerp(a.borderData, b.borderData, t),
        centerSpaceColor: Color.lerp(a.centerSpaceColor, b.centerSpaceColor, t),
        centerSpaceRadiusRatio: lerpDoubleAllowInfinity(
          a.centerSpaceRadiusRatio,
          b.centerSpaceRadiusRatio,
          t,
        ),
        pieTouchData: b.pieTouchData,
        sectionsSpace: lerpDouble(a.sectionsSpace, b.sectionsSpace, t),
        startDegreeOffset:
            lerpDouble(a.startDegreeOffset, b.startDegreeOffset, t),
        sections: lerpPieChartSectionDataList(a.sections, b.sections, t),
        titleSunbeamLayout: b.titleSunbeamLayout,
        showZeroTitle: t < 0.5 ? a.showZeroTitle : b.showZeroTitle,
        strokeCapRoundMode:
            t < 0.5 ? a.strokeCapRoundMode : b.strokeCapRoundMode,
        centerSpaceBorder: a.centerSpaceBorder == null
            ? b.centerSpaceBorder
            : b.centerSpaceBorder == null
                ? a.centerSpaceBorder
                : BorderSide.lerp(
                    a.centerSpaceBorder!,
                    b.centerSpaceBorder!,
                    t,
                  ),
        sectionsBorder: a.sectionsBorder == null
            ? b.sectionsBorder
            : b.sectionsBorder == null
                ? a.sectionsBorder
                : BorderSide.lerp(a.sectionsBorder!, b.sectionsBorder!, t),
      );
    } else {
      throw Exception('Illegal State');
    }
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        sections,
        centerSpaceRadiusRatio,
        centerSpaceColor,
        pieTouchData,
        sectionsSpace,
        startDegreeOffset,
        borderData,
        titleSunbeamLayout,
        showZeroTitle,
        strokeCapRoundMode,
      ];
}

/// Holds data related to drawing each [PieChart] section.
class PieChartSectionData {
  /// [PieChart] draws section from right side of the circle (0 degrees),
  /// each section have a [value] that determines how much it should occupy,
  /// this is depends on sum of all sections, each section should
  /// occupy ([value] / sumValues) * 360 degrees.
  ///
  /// It draws this section with filled [color], and [radiusRatio].
  ///
  /// If [showTitle] is true, it draws a title at the middle of section,
  /// you can set the text using [title], and set the style using [titleStyle],
  /// by default it draws texts at the middle of section, but you can change the
  /// [titlePositionPercentageOffset] to have your desire design,
  /// it should be between 0.0 to 1.0,
  /// 0.0 means near the center,
  /// 1.0 means near the outside of the [PieChart].
  ///
  /// If [badgeWidget] is not null, it draws a widget at the middle of section,
  /// by default it draws the widget at the middle of section, but you can
  /// change the [badgePositionPercentageOffset] to have your desire design,
  /// the value works the same way as [titlePositionPercentageOffset].
  PieChartSectionData({
    num? value,
    this.color,
    this.gradient,
    this.radiusRatio,
    bool? showTitle,
    this.titleStyle,
    String? title,
    BorderSide? borderSide,
    this.badgeWidget,
    double? titlePositionPercentageOffset,
    double? badgePositionPercentageOffset,
  })  : assert(radiusRatio == null || (radiusRatio >= 0 && radiusRatio <= 1)),
        value = value ?? 0,
        showTitle = showTitle ?? true,
        title = title ?? (value == null ? '' : value.toString()),
        borderSide = borderSide ?? const BorderSide(width: 0),
        titlePositionPercentageOffset = titlePositionPercentageOffset ?? 0.5,
        badgePositionPercentageOffset = badgePositionPercentageOffset ?? 0.5;

  /// It determines how much space it should occupy around the circle.
  ///
  /// This is depends on sum of all sections, each section should
  /// occupy ([value] / sumValues) * 360 degrees.
  ///
  /// value can not be null.
  final num value;

  /// Defines the color of section.
  final Color? color;

  /// Defines the gradient of section. If specified, overrides the color
  /// setting.
  final Gradient? gradient;

  /// Defines the radius of section.
  final double? radiusRatio;

  /// Defines show or hide the title of section.
  final bool showTitle;

  /// Defines style of showing title of section.
  final TextStyle? titleStyle;

  /// Defines text of showing title at the middle of section.
  final String title;

  /// Defines border stroke around the section
  final BorderSide borderSide;

  /// Defines a widget that represents the section.
  ///
  /// This can be anything from a text, an image, an animation, and even a
  /// combination of widgets.
  /// Use AnimatedWidgets to animate this widget.
  final Widget? badgeWidget;

  /// Defines position of showing title in the section.
  ///
  /// It should be between 0.0 to 1.0,
  /// 0.0 means near the center,
  /// 1.0 means near the outside of the [PieChart].
  final double titlePositionPercentageOffset;

  /// Defines position of badge widget in the section.
  ///
  /// It should be between 0.0 to 1.0,
  /// 0.0 means near the center,
  /// 1.0 means near the outside of the [PieChart].
  final double badgePositionPercentageOffset;

  /// Copies current [PieChartSectionData] to a new [PieChartSectionData],
  /// and replaces provided values.
  PieChartSectionData copyWith({
    double? value,
    Color? color,
    Gradient? gradient,
    double? radiusRatio,
    bool? showTitle,
    TextStyle? titleStyle,
    String? title,
    BorderSide? borderSide,
    Widget? badgeWidget,
    double? titlePositionPercentageOffset,
    double? badgePositionPercentageOffset,
    double? borderRadius,
  }) {
    return PieChartSectionData(
      value: value ?? this.value,
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      radiusRatio: radiusRatio ?? this.radiusRatio,
      showTitle: showTitle ?? this.showTitle,
      titleStyle: titleStyle ?? this.titleStyle,
      title: title ?? this.title,
      borderSide: borderSide ?? this.borderSide,
      badgeWidget: badgeWidget ?? this.badgeWidget,
      titlePositionPercentageOffset:
          titlePositionPercentageOffset ?? this.titlePositionPercentageOffset,
      badgePositionPercentageOffset:
          badgePositionPercentageOffset ?? this.badgePositionPercentageOffset,
    );
  }

  /// Lerps a [PieChartSectionData] based on [t] value, check [Tween.lerp].
  static PieChartSectionData lerp(
    PieChartSectionData a,
    PieChartSectionData b,
    double t,
  ) {
    return PieChartSectionData(
      value: lerpDouble(a.value, b.value, t),
      color: Color.lerp(a.color, b.color, t),
      gradient: Gradient.lerp(a.gradient, b.gradient, t),
      radiusRatio: lerpDouble(a.radiusRatio, b.radiusRatio, t),
      showTitle: b.showTitle,
      titleStyle: TextStyle.lerp(a.titleStyle, b.titleStyle, t),
      title: b.title,
      borderSide: BorderSide.lerp(a.borderSide, b.borderSide, t),
      badgeWidget: b.badgeWidget,
      titlePositionPercentageOffset: lerpDouble(
        a.titlePositionPercentageOffset,
        b.titlePositionPercentageOffset,
        t,
      ),
      badgePositionPercentageOffset: lerpDouble(
        a.badgePositionPercentageOffset,
        b.badgePositionPercentageOffset,
        t,
      ),
    );
  }
}

/// Holds data to handle touch events, and touch responses in the [PieChart].
///
/// There is a touch flow, explained [here](https://github.com/imaNNeo/fl_chart/blob/main/repo_files/documentations/handle_touches.md)
/// in a simple way, each chart's renderer captures the touch events, and
/// passes the pointerEvent to the painter, and gets touched spot, and wraps it
/// into a concrete [PieTouchResponse].
class PieTouchData extends FlTouchData<PieTouchResponse> with EquatableMixin {
  /// You can disable or enable the touch system using [enabled] flag,
  ///
  /// [touchCallback] notifies you about the happened touch/pointer events.
  /// It gives you a [FlTouchEvent] which is the happened event such as
  /// [FlPointerHoverEvent], [FlTapUpEvent], ...
  /// It also gives you a [PieTouchResponse] which contains information
  /// about the elements that has touched.
  ///
  /// Using [mouseCursorResolver] you can change the mouse cursor
  /// based on the provided [FlTouchEvent] and [PieTouchResponse]
  PieTouchData({
    bool? enabled,
    BaseTouchCallback<PieTouchResponse>? touchCallback,
    MouseCursorResolver<PieTouchResponse>? mouseCursorResolver,
    Duration? longPressDuration,
    PieTouchTooltipData? touchTooltipData,
    this.handleBuiltInTouches = true,
  })  : touchTooltipData = touchTooltipData ?? PieTouchTooltipData(),
        super(
          enabled ?? true,
          touchCallback,
          mouseCursorResolver,
          longPressDuration,
        );

  final PieTouchTooltipData touchTooltipData;
  final bool handleBuiltInTouches;

  PieTouchData copyWith({
    bool? enabled,
    BaseTouchCallback<PieTouchResponse>? touchCallback,
    MouseCursorResolver<PieTouchResponse>? mouseCursorResolver,
    Duration? longPressDuration,
    PieTouchTooltipData? touchTooltipData,
    bool? handleBuiltInTouches,
  }) {
    return PieTouchData(
      enabled: enabled ?? this.enabled,
      touchCallback: touchCallback ?? this.touchCallback,
      mouseCursorResolver: mouseCursorResolver ?? this.mouseCursorResolver,
      longPressDuration: longPressDuration ?? this.longPressDuration,
      touchTooltipData: touchTooltipData ?? this.touchTooltipData,
      handleBuiltInTouches: handleBuiltInTouches ?? this.handleBuiltInTouches,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        enabled,
        touchCallback,
        mouseCursorResolver,
        longPressDuration,
        handleBuiltInTouches,
        touchTooltipData,
      ];
}

class PieTouchTooltipData with EquatableMixin {
  /// if [BarTouchData.handleBuiltInTouches] is true,
  /// [BarChart] shows a tooltip popup on top of rods automatically when touch happens,
  /// otherwise you can show it manually using [BarChartGroupData.showingTooltipIndicators].
  /// Tooltip shows on top of rods, with [getTooltipColor] as a background color,
  /// and you can set corner radius using [tooltipRoundedRadius].
  /// If you want to have a padding inside the tooltip, fill [tooltipPadding],
  /// or If you want to have a bottom margin, set [tooltipMargin].
  /// Content of the tooltip will provide using [getTooltipItem] callback, you can override it
  /// and pass your custom data to show in the tooltip.
  /// You can restrict the tooltip's width using [maxContentWidth].
  /// Sometimes, [BarChart] shows the tooltip outside of the chart,
  /// you can set [fitInsideHorizontally] true to force it to shift inside the chart horizontally,
  /// also you can set [fitInsideVertically] true to force it to shift inside the chart vertically.
  PieTouchTooltipData({
    double? tooltipRoundedRadius,
    EdgeInsets? tooltipPadding,
    double? tooltipVerticalMargin,
    double? maxContentWidth,
    GetPieTooltipItem? getTooltipItem,
    this.getTooltipColor,
    bool? fitInsideHorizontally,
    bool? fitInsideVertically,
    TooltipDirection? direction,
    double? rotateAngle,
    BorderSide? tooltipBorder,
  })  : tooltipRoundedRadius = tooltipRoundedRadius ?? 8,
        tooltipPadding = tooltipPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tooltipVerticalMargin = tooltipVerticalMargin ?? 8.0,
        maxContentWidth = maxContentWidth ?? 120,
        getTooltipItem = getTooltipItem ?? defaultPieTooltipItem,
        fitInsideHorizontally = fitInsideHorizontally ?? false,
        fitInsideVertically = fitInsideVertically ?? false,
        direction = direction ?? TooltipDirection.auto,
        rotateAngle = rotateAngle ?? 0.0,
        tooltipBorder = tooltipBorder ?? BorderSide.none,
        super();

  /// Sets a rounded radius for the tooltip.
  final double tooltipRoundedRadius;

  /// Applies a padding for showing contents inside the tooltip.
  final EdgeInsets tooltipPadding;

  /// Applies vertical offset for showing tooltip, default is 8.
  final double tooltipVerticalMargin;

  /// Restricts the tooltip's width.
  final double maxContentWidth;

  /// Retrieves data for showing content inside the tooltip.
  final GetPieTooltipItem getTooltipItem;

  /// Forces the tooltip to shift horizontally inside the chart, if overflow happens.
  final bool fitInsideHorizontally;

  /// Forces the tooltip to shift vertically inside the chart, if overflow happens.
  final bool fitInsideVertically;

  /// Controls showing tooltip on top or bottom, default is auto.
  final TooltipDirection direction;

  /// Controls the rotation of the tooltip.
  final double rotateAngle;

  /// The tooltip border color.
  final BorderSide tooltipBorder;

  /// Retrieves data for setting background color of the tooltip.
  final GetPieTooltipColor? getTooltipColor;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        tooltipRoundedRadius,
        tooltipPadding,
        tooltipVerticalMargin,
        maxContentWidth,
        getTooltipItem,
        fitInsideHorizontally,
        fitInsideVertically,
        rotateAngle,
        tooltipBorder,
        getTooltipColor,
        direction,
      ];
}

typedef GetPieTooltipItem = PieTooltipItem? Function(
  PieChartSectionData touchedSection,
  int touchedIndex,
);

PieTooltipItem? defaultPieTooltipItem(
  PieChartSectionData touchedSection,
  int touchedIndex,
) {
  final color = touchedSection.gradient?.colors.first ?? touchedSection.color;
  return PieTooltipItem(
    touchedSection.value.toString(),
    indicator: FlTooltipIndicator(color: color),
  );
}

typedef GetPieTooltipColor = Color Function(
  PieChartSectionData touchedSection,
  int touchedIndex,
);

class PieTooltipItem extends BarTooltipItem {
  PieTooltipItem(
    super.text, {
    super.textStyle,
    super.textAlign = TextAlign.center,
    super.textDirection = TextDirection.ltr,
    super.children,
    super.indicator,
  });
}

class PieTouchedSection with EquatableMixin {
  /// This class Contains [touchedSection], [touchedSectionIndex] that tells
  /// you touch happened on which section,
  /// [touchAngle] gives you angle of touch,
  /// and [touchRadius] gives you radius of the touch.
  PieTouchedSection(
    this.touchedSection,
    this.touchedSectionIndex,
    this.touchAngle,
    this.touchRadius,
  );

  /// touch happened on this section
  final PieChartSectionData? touchedSection;

  /// touch happened on this position
  final int touchedSectionIndex;

  /// touch happened with this angle on the [PieChart]
  final double touchAngle;

  /// touch happened with this radius on the [PieChart]
  final double touchRadius;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        touchedSection,
        touchedSectionIndex,
        touchAngle,
        touchRadius,
      ];
}

/// Holds information about touch response in the [PieChart].
///
/// You can override [PieTouchData.touchCallback] to handle touch events,
/// it gives you a [PieTouchResponse] and you can do whatever you want.
class PieTouchResponse extends BaseTouchResponse {
  /// If touch happens, [PieChart] processes it internally and passes out a
  /// [PieTouchResponse]
  PieTouchResponse(this.touchedSection, this.touchPosition) : super();

  /// Contains information about touched section, like index, angle, radius, ...
  final PieTouchedSection? touchedSection;
  final Offset touchPosition;

  /// Copies current [PieTouchResponse] to a new [PieTouchResponse],
  /// and replaces provided values.
  PieTouchResponse copyWith({
    PieTouchedSection? touchedSection,
    Offset? touchPosition,
  }) {
    return PieTouchResponse(
      touchedSection ?? this.touchedSection,
      touchPosition ?? this.touchPosition,
    );
  }
}

/// It lerps a [PieChartData] to another [PieChartData] (handles animation for
/// updating values)
class PieChartDataTween extends Tween<PieChartData> {
  PieChartDataTween({required PieChartData begin, required PieChartData end})
      : super(begin: begin, end: end);

  /// Lerps a [PieChartData] based on [t] value, check [Tween.lerp].
  @override
  PieChartData lerp(double t) => begin!.lerp(begin!, end!, t);
}

enum PieStrokeCapRoundMode {
  toStart,
  toEnd,
  both,
}
