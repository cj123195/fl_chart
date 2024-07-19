import 'dart:math' as math;
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/base/line.dart';
import 'package:fl_chart/src/extensions/paint_extension.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:flutter/material.dart';

/// Paints [PieChartData] in the canvas, it can be used in a [CustomPainter]
class PieChartPainter extends BaseChartPainter<PieChartData> {
  /// Paints dataList into canvas, it is the animating [PieChartData],
  /// targetData is the animation's target and remains the same
  /// during animation, then we should use it  when we need to show
  /// tooltips or something like that, because dataList is changing constantly.
  ///
  /// textScale used for scaling texts inside the chart,
  /// parent can use MediaQuery.textScaleFactor to respect
  /// the system's font size.
  PieChartPainter() : super() {
    _sectionPaint = Paint()..style = PaintingStyle.stroke;

    _sectionSaveLayerPaint = Paint();

    _sectionStrokePaint = Paint()..style = PaintingStyle.stroke;

    _centerSpacePaint = Paint()..style = PaintingStyle.fill;
  }

  late Paint _sectionPaint;
  late Paint _sectionSaveLayerPaint;
  late Paint _sectionStrokePaint;
  late Paint _centerSpacePaint;

  /// Paints [PieChartData] into the provided canvas.
  @override
  void paint(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<PieChartData> holder, [
    BaseTouchResponse? touchResponse,
  ]) {
    super.paint(context, canvasWrapper, holder);
    final data = holder.data;
    if (data.sections.isEmpty) {
      return;
    }

    final sectionsAngle = calculateSectionsAngle(data.sections, data.sumValue);
    final centerRadius = calculateCenterRadius(canvasWrapper.size, holder);

    drawCenterSpace(canvasWrapper, centerRadius, holder);
    drawSections(context, canvasWrapper, sectionsAngle, centerRadius, holder);
    drawBorder(canvasWrapper, centerRadius, holder);
    drawTexts(context, canvasWrapper, holder, centerRadius, sectionsAngle);

    if (touchResponse != null) {
      drawTouchTooltip(
        context,
        canvasWrapper,
        holder,
        touchResponse as PieTouchResponse,
      );
    }
  }

  @visibleForTesting
  void drawCenterSpace(
    CanvasWrapper canvasWrapper,
    double centerRadius,
    PaintHolder<PieChartData> holder,
  ) {
    final data = holder.data;
    final viewSize = canvasWrapper.size;
    final centerX = viewSize.width / 2;
    final centerY = viewSize.height / 2;

    _centerSpacePaint.color = data.centerSpaceColor;
    canvasWrapper.drawCircle(
      Offset(centerX, centerY),
      centerRadius,
      _centerSpacePaint,
    );

    if (data.centerSpaceBorder != null) {
      final border = data.centerSpaceBorder!;
      canvasWrapper.drawCircle(
        Offset(centerX, centerY),
        centerRadius + border.strokeOffset / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = border.color
          ..strokeWidth = border.width
          ..strokeJoin,
      );
    }
  }

  @visibleForTesting
  List<double> calculateSectionsAngle(
    List<PieChartSectionData> sections,
    num sumValue,
  ) {
    if (sections.every((e) => e.value == 0)) {
      return List.generate(sections.length, (index) => 360 / sections.length);
    }

    return sections.map((section) {
      return 360 * (section.value / sumValue);
    }).toList();
  }

  double calculateSectionRadius(
    Size viewSize,
    PieChartData data,
    PieChartSectionData section,
  ) {
    final radiusRatio = section.radiusRatio ?? 1;
    var radius = math.min(viewSize.width, viewSize.height) / 2;
    if (data.sectionsBorder != null) {
      radius = radius - data.sectionsBorder!.strokeOffset;
    }
    return (radius -
            viewSize.shortestSide * data.centerSpaceRadiusRatio / 2 -
            section.borderSide.strokeOffset * 2) *
        radiusRatio;
  }

  @visibleForTesting
  void drawBorder(
    CanvasWrapper canvasWrapper,
    double centerRadius,
    PaintHolder<PieChartData> holder,
  ) {
    final data = holder.data;
    final viewSize = canvasWrapper.size;
    final center = Offset(viewSize.width / 2, viewSize.height / 2);

    if (data.sectionsBorder == null || data.sections.isEmpty) {
      return;
    }

    final border = data.sectionsBorder!;
    final sectionRadius = calculateSectionRadius(
      viewSize,
      data,
      data.sections.first,
    );
    final radius = centerRadius + sectionRadius + border.strokeOffset / 2;

    canvasWrapper.drawCircle(
      center,
      radius,
      border.toPaint(),
    );
  }

  @visibleForTesting
  void drawSections(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    List<double> sectionsAngle,
    double centerRadius,
    PaintHolder<PieChartData> holder,
  ) {
    final data = holder.data;
    final viewSize = canvasWrapper.size;

    final center = Offset(viewSize.width / 2, viewSize.height / 2);

    var tempAngle = data.startDegreeOffset;

    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      final sectionDegree = sectionsAngle[i];
      final sectionRadius = calculateSectionRadius(viewSize, data, section);

      double? capAngle;
      if (data.isStrokeCapRound == true && data.centerSpaceRadiusRatio > 0) {
        final d = math.min(viewSize.width, viewSize.height);
        capAngle = (sectionRadius / 2) / (math.pi * d) * 360;
      }

      if (sectionDegree == 360) {
        final radius = centerRadius + sectionRadius / 2;
        final rect = Rect.fromCircle(center: center, radius: radius);
        _sectionPaint
          ..setColorOrGradient(
            section.color,
            section.gradient,
            rect,
          )
          ..strokeWidth = sectionRadius
          ..style = PaintingStyle.fill;

        final bounds = Rect.fromCircle(
          center: center,
          radius: centerRadius + sectionRadius,
        );
        canvasWrapper
          ..saveLayer(bounds, _sectionSaveLayerPaint)
          ..drawCircle(
            center,
            centerRadius + sectionRadius,
            _sectionPaint..blendMode = BlendMode.srcOver,
          )
          ..drawCircle(
            center,
            centerRadius,
            _sectionPaint..blendMode = BlendMode.srcOut,
          )
          ..restore();
        _sectionPaint.blendMode = BlendMode.srcOver;
        if (section.borderSide.width != 0.0 &&
            section.borderSide.color.opacity != 0.0) {
          _sectionStrokePaint
            ..strokeWidth = section.borderSide.width
            ..color = section.borderSide.color;
          // Outer
          canvasWrapper
            ..drawCircle(
              center,
              centerRadius + sectionRadius - (section.borderSide.width / 2),
              _sectionStrokePaint,
            )

            // Inner
            ..drawCircle(
              center,
              centerRadius + (section.borderSide.width / 2),
              _sectionStrokePaint,
            );
        }
        return;
      }

      final sectionPath = generateSectionPath(
        section,
        sectionRadius,
        data.sectionsSpace,
        tempAngle,
        sectionDegree,
        center,
        centerRadius,
        capAngle: capAngle,
      );

      drawSection(context, section, sectionPath, canvasWrapper);
      drawSectionStroke(section, sectionPath, canvasWrapper, viewSize);
      tempAngle += sectionDegree;
    }
  }

  /// Generates a path around a section
  @visibleForTesting
  Path generateSectionPath(
    PieChartSectionData section,
    double sectionRadius,
    double sectionSpace,
    double tempAngle,
    double sectionDegree,
    Offset center,
    double centerRadius, {
    double? capAngle,
  }) {
    final sectionRadiusRect = Rect.fromCircle(
      center: center,
      radius: centerRadius + sectionRadius,
    );

    final centerRadiusRect = Rect.fromCircle(
      center: center,
      radius: centerRadius,
    );

    var startRadians = Utils().radians(tempAngle);
    final sweepRadians = Utils().radians(sectionDegree);
    var endRadians = startRadians + sweepRadians;
    if (capAngle != null && capAngle > 0) {
      final capRadians = Utils().radians(capAngle);
      startRadians += capRadians;
      endRadians += capRadians;
    }

    final startLineDirection =
        Offset(math.cos(startRadians), math.sin(startRadians));

    final startLineFrom = center + startLineDirection * centerRadius;
    final startLineTo = startLineFrom + startLineDirection * sectionRadius;

    final endLineDirection = Offset(math.cos(endRadians), math.sin(endRadians));

    final endLineFrom = center + endLineDirection * centerRadius;
    final endLineTo = endLineFrom + endLineDirection * sectionRadius;

    var sectionPath = Path();
    if (capAngle == null) {
      sectionPath
        ..moveTo(startLineFrom.dx, startLineFrom.dy)
        ..lineTo(startLineTo.dx, startLineTo.dy)
        ..arcTo(sectionRadiusRect, startRadians, sweepRadians, false)
        ..lineTo(endLineFrom.dx, endLineFrom.dy)
        ..arcTo(centerRadiusRect, endRadians, -sweepRadians, false)
        ..moveTo(startLineFrom.dx, startLineFrom.dy)
        ..close();
    } else {
      sectionPath
        ..moveTo(startLineFrom.dx, startLineFrom.dy)
        ..arcToPoint(startLineTo, radius: Radius.circular(sectionRadius / 2))
        ..arcTo(sectionRadiusRect, startRadians, sweepRadians, false)
        ..arcToPoint(endLineFrom,
            radius: Radius.circular(sectionRadius / 2), clockwise: false)
        ..arcTo(centerRadiusRect, endRadians, -sweepRadians, false)
        ..moveTo(startLineFrom.dx, startLineFrom.dy)
        ..close();
    }

    /// Subtract section space from the sectionPath
    if (sectionSpace != 0) {
      final startLineSeparatorPath = createRectPathAroundLine(
        Line(startLineFrom, startLineTo),
        sectionSpace,
      );
      try {
        sectionPath = Path.combine(
          PathOperation.difference,
          sectionPath,
          startLineSeparatorPath,
        );
      } catch (e) {
        /// It's a flutter engine issue with [Path.combine] in web-html renderer
        /// https://github.com/imaNNeo/fl_chart/issues/955
      }

      final endLineSeparatorPath =
          createRectPathAroundLine(Line(endLineFrom, endLineTo), sectionSpace);
      try {
        sectionPath = Path.combine(
          PathOperation.difference,
          sectionPath,
          endLineSeparatorPath,
        );
      } catch (e) {
        /// It's a flutter engine issue with [Path.combine] in web-html renderer
        /// https://github.com/imaNNeo/fl_chart/issues/955
      }
    }

    return sectionPath;
  }

  /// Creates a rect around a narrow line
  @visibleForTesting
  Path createRectPathAroundLine(Line line, double width) {
    width = width / 2;
    final normalized = line.normalize();

    final verticalAngle = line.direction() + (math.pi / 2);
    final verticalDirection =
        Offset(math.cos(verticalAngle), math.sin(verticalAngle));

    final startPoint1 = Offset(
      line.from.dx -
          (normalized * (width / 2)).dx -
          (verticalDirection * width).dx,
      line.from.dy -
          (normalized * (width / 2)).dy -
          (verticalDirection * width).dy,
    );

    final startPoint2 = Offset(
      line.to.dx +
          (normalized * (width / 2)).dx -
          (verticalDirection * width).dx,
      line.to.dy +
          (normalized * (width / 2)).dy -
          (verticalDirection * width).dy,
    );

    final startPoint3 = Offset(
      startPoint2.dx + (verticalDirection * (width * 2)).dx,
      startPoint2.dy + (verticalDirection * (width * 2)).dy,
    );

    final startPoint4 = Offset(
      startPoint1.dx + (verticalDirection * (width * 2)).dx,
      startPoint1.dy + (verticalDirection * (width * 2)).dy,
    );

    return Path()
      ..moveTo(startPoint1.dx, startPoint1.dy)
      ..lineTo(startPoint2.dx, startPoint2.dy)
      ..lineTo(startPoint3.dx, startPoint3.dy)
      ..lineTo(startPoint4.dx, startPoint4.dy)
      ..lineTo(startPoint1.dx, startPoint1.dy);
  }

  @visibleForTesting
  void drawSection(
    BuildContext context,
    PieChartSectionData section,
    Path sectionPath,
    CanvasWrapper canvasWrapper,
  ) {
    _sectionPaint
      ..setColorOrGradient(
        section.color ?? Theme.of(context).colorScheme.primary,
        section.gradient,
        sectionPath.getBounds(),
      )
      ..style = PaintingStyle.fill;
    canvasWrapper.drawPath(sectionPath, _sectionPaint);
  }

  @visibleForTesting
  void drawSectionStroke(
    PieChartSectionData section,
    Path sectionPath,
    CanvasWrapper canvasWrapper,
    Size viewSize,
  ) {
    if (section.borderSide.width != 0.0 &&
        section.borderSide.color.opacity != 0.0) {
      canvasWrapper
        ..saveLayer(
          Rect.fromLTWH(0, 0, viewSize.width, viewSize.height),
          Paint(),
        )
        ..clipPath(sectionPath);

      _sectionStrokePaint
        ..strokeWidth = section.borderSide.width * 2
        ..color = section.borderSide.color;
      canvasWrapper
        ..drawPath(
          sectionPath,
          _sectionStrokePaint,
        )
        ..restore();
    }
  }

  /// Calculates layout of overlaying elements, includes:
  /// - title text
  /// - badge widget positions
  @visibleForTesting
  void drawTexts(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<PieChartData> holder,
    double centerRadius,
    List<double> sectionsAngle,
  ) {
    final data = holder.data;
    final viewSize = canvasWrapper.size;
    final center = Offset(viewSize.width / 2, viewSize.height / 2);

    var tempAngle = data.startDegreeOffset;

    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      final sweepAngle = sectionsAngle[i];

      if (!section.showTitle ||
          (data.sumValue != 0 && section.value == 0 && !data.showZeroTitle)) {
        tempAngle += sweepAngle;
        continue;
      }

      final sectionRadius = calculateSectionRadius(viewSize, data, section);
      final startAngle = tempAngle;
      final sectionCenterAngle = startAngle + (sweepAngle / 2);

      double? rotateAngle;
      if (data.titleSunbeamLayout) {
        if (sectionCenterAngle >= 90 && sectionCenterAngle <= 270) {
          rotateAngle = sectionCenterAngle - 180;
        } else {
          rotateAngle = sectionCenterAngle;
        }
      }

      final degree = Utils().radians(sectionCenterAngle);
      Offset sectionCenter(double percentageOffset) =>
          center +
          Offset(
            math.cos(degree) *
                (centerRadius + (sectionRadius * percentageOffset)),
            math.sin(degree) *
                (centerRadius + (sectionRadius * percentageOffset)),
          );

      final sectionCenterOffsetTitle =
          sectionCenter(section.titlePositionPercentageOffset);

      if (section.showTitle) {
        final span = TextSpan(
          style: Utils().getThemeAwareTextStyle(context, section.titleStyle),
          text: section.title,
        );
        final tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          textScaler: holder.textScaler,
        )..layout();

        canvasWrapper.drawText(
          tp,
          sectionCenterOffsetTitle - Offset(tp.width / 2, tp.height / 2),
          rotateAngle,
        );
      }

      tempAngle += sweepAngle;
    }
  }

  @visibleForTesting
  void drawTouchTooltip(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<PieChartData> holder,
    PieTouchResponse touchResponse,
  ) {
    final data = holder.data;
    final tooltipData = data.pieTouchData.touchTooltipData;
    final viewSize = canvasWrapper.size;

    final section = touchResponse.touchedSection?.touchedSection;
    if (section == null) {
      return;
    }
    final sectionIndex = touchResponse.touchedSection!.touchedSectionIndex;

    final tooltipItem = tooltipData.getTooltipItem(section, sectionIndex);
    if (tooltipItem == null) {
      return;
    }

    const textsBelowMargin = 4;

    final span = TextSpan(
      style: Utils().getThemeAwareTextStyle(context, tooltipItem.textStyle),
      text: tooltipItem.text,
      children: tooltipItem.children,
    );

    final tp = TextPainter(
      text: span,
      textAlign: tooltipItem.textAlign,
      textDirection: tooltipItem.textDirection,
      textScaler: holder.textScaler,
    )..layout(maxWidth: tooltipData.maxContentWidth);

    /// creating TextPainters to calculate the width and height of the tooltip
    final drawingTextPainter = tp;

    /// biggerWidth
    /// some texts maybe larger, then we should
    /// draw the tooltip' width as wide as biggerWidth
    ///
    /// sumTextsHeight
    /// sum up all Texts height, then we should
    /// draw the tooltip's height as tall as sumTextsHeight
    final textWidth = drawingTextPainter.width;
    final textHeight = drawingTextPainter.height + textsBelowMargin;

    var innerWidth = textWidth;
    var innerHeight = textHeight;
    if (tooltipItem.indicator != null) {
      innerWidth += tooltipItem.indicator!.width + 8.0;
      innerHeight = max(innerHeight, tooltipItem.indicator!.height);
    }
    final tooltipWidth = innerWidth + tooltipData.tooltipPadding.horizontal;
    final tooltipHeight = innerHeight + tooltipData.tooltipPadding.vertical;

    final offset = touchResponse.touchPosition;
    final margin = tooltipData.tooltipVerticalMargin;
    final direction = tooltipData.direction;
    var tooltipTop = switch (direction) {
      TooltipDirection.auto => offset.dy - tooltipHeight - margin,
      TooltipDirection.top => offset.dy - tooltipHeight - margin,
      TooltipDirection.bottom => offset.dy + margin,
    };
    var tooltipLeft = offset.dx - tooltipWidth / 2;

    if (tooltipData.fitInsideVertically) {
      switch (tooltipData.direction) {
        case TooltipDirection.auto:
          if (tooltipTop < 0) {
            tooltipTop = offset.dy + tooltipData.tooltipVerticalMargin;
            if (tooltipTop + tooltipHeight > viewSize.height) {
              tooltipTop = 0;
            }
          }
        case TooltipDirection.top:
          if (tooltipTop < 0) tooltipTop = 0;
        case TooltipDirection.bottom:
          if (tooltipTop + tooltipHeight > viewSize.height) {
            tooltipTop = viewSize.height - tooltipHeight;
          }
      }
    }

    if (tooltipData.fitInsideHorizontally) {
      if (tooltipLeft < 0) {
        tooltipLeft = 0;
      } else if (tooltipLeft + tooltipWidth > viewSize.width) {
        tooltipLeft = viewSize.width - tooltipWidth;
      }
    }

    /// draw the background rect with rounded radius
    // ignore: omit_local_variable_types
    final Rect rect = Rect.fromLTWH(
      tooltipLeft,
      tooltipTop,
      tooltipWidth,
      tooltipHeight,
    );

    final radius = Radius.circular(tooltipData.tooltipRoundedRadius);
    final roundedRect = RRect.fromRectAndCorners(
      rect,
      topLeft: radius,
      topRight: radius,
      bottomLeft: radius,
      bottomRight: radius,
    );

    /// set tooltip's background color for each rod
    final bgTouchTooltipPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = tooltipData.getTooltipColor == null
          ? Theme.of(context).colorScheme.background
          : tooltipData.getTooltipColor!(section, sectionIndex);

    final tooltipRotateAngle = tooltipData.rotateAngle;
    final rectRotationOffset = Offset(
      0,
      Utils().calculateRotationOffset(rect.size, tooltipRotateAngle).dy,
    );
    final rectDrawOffset = Offset(roundedRect.left, roundedRect.top);

    final textRotationOffset =
        Utils().calculateRotationOffset(tp.size, tooltipRotateAngle);

    /// draw the texts one by one in below of each other
    final top = tooltipData.tooltipPadding.top;
    final drawOffset = Offset(
      rect.center.dx - (innerWidth / 2),
      rect.topCenter.dy + top - textRotationOffset.dy + rectRotationOffset.dy,
    );

    final borderTouchTooltipPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.transparent
      ..strokeWidth = 1.0;
    if (tooltipData.tooltipBorder != BorderSide.none) {
      borderTouchTooltipPaint
        ..color = tooltipData.tooltipBorder.color
        ..strokeWidth = tooltipData.tooltipBorder.width;
    }

    canvasWrapper.drawRotated(
      size: rect.size,
      rotationOffset: rectRotationOffset,
      drawOffset: rectDrawOffset,
      angle: tooltipRotateAngle,
      drawCallback: () {
        canvasWrapper
          ..drawShadow(
            Path()..addRRect(roundedRect),
            Theme.of(context).colorScheme.shadow.withOpacity(0.3),
            10,
          )
          ..drawRRect(roundedRect, bgTouchTooltipPaint)
          ..drawRRect(roundedRect, borderTouchTooltipPaint);
        final indicator = tooltipItem.indicator;
        var textOffset = drawOffset;
        // canvasWrapper.drawText(tp, drawOffset);
        if (indicator != null) {
          drawTooltipIndicator(
            canvasWrapper,
            Offset(
              drawOffset.dx,
              drawOffset.dy + (innerHeight - indicator.height) / 2,
            ),
            indicator,
          );
          textOffset = textOffset.translate(
            indicator.width + 8.0,
            (innerHeight - tp.height) / 2,
          );
          canvasWrapper.drawText(tp, textOffset);
        } else {
          canvasWrapper.drawText(tp, drawOffset);
        }
      },
    );
  }

  void drawTooltipIndicator(
    CanvasWrapper canvasWrapper,
    Offset offset,
    FlTooltipIndicator indicator,
  ) {
    final width = indicator.width;
    final height = indicator.height;
    final radius = max(width, height) / 2;
    final rect = Rect.fromLTWH(offset.dx, offset.dy, width, height);
    final paint = Paint()
      ..setColorOrGradient(indicator.color, indicator.gradient, rect)
      ..style = indicator.style;
    if (indicator.shape == BoxShape.rectangle) {
      canvasWrapper.drawRRect(
        RRect.fromRectAndRadius(rect, indicator.radius ?? Radius.zero),
        paint,
      );
    } else {
      canvasWrapper.drawCircle(
        Offset(offset.dx + width / 2, offset.dy + height / 2),
        radius,
        paint,
      );
    }
  }

  /// Calculates center radius based on the provided sections radius
  @visibleForTesting
  double calculateCenterRadius(
    Size viewSize,
    PaintHolder<PieChartData> holder,
  ) {
    final data = holder.data;
    return viewSize.shortestSide * data.centerSpaceRadiusRatio / 2;
  }

  /// Makes a [PieTouchedSection] based on the provided [localPosition]
  ///
  /// Processes [localPosition] and checks
  /// the elements of the chart that are near the offset,
  /// then makes a [PieTouchedSection] from the elements that has been touched.
  PieTouchedSection handleTouch(
    Offset localPosition,
    Size viewSize,
    PaintHolder<PieChartData> holder,
  ) {
    final data = holder.data;
    final sectionsAngle = calculateSectionsAngle(data.sections, data.sumValue);

    final center = Offset(viewSize.width / 2, viewSize.height / 2);

    final touchedPoint2 = localPosition - center;

    final touchX = touchedPoint2.dx;
    final touchY = touchedPoint2.dy;

    final touchR = math.sqrt(math.pow(touchX, 2) + math.pow(touchY, 2));
    var touchAngle = Utils().degrees(math.atan2(touchY, touchX));
    touchAngle = touchAngle < 0 ? (180 - touchAngle.abs()) + 180 : touchAngle;

    PieChartSectionData? foundSectionData;
    var foundSectionDataPosition = -1;

    /// Find the nearest section base on the touch spot
    final relativeTouchAngle = (touchAngle - data.startDegreeOffset) % 360;
    var tempAngle = 0.0;
    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      var sectionAngle = sectionsAngle[i];

      tempAngle %= 360;
      if (data.sections.length == 1) {
        sectionAngle = 360;
      } else {
        sectionAngle %= 360;
      }

      /// radius criteria
      final centerRadius = calculateCenterRadius(viewSize, holder);
      final sectionRadius =
          centerRadius + calculateSectionRadius(viewSize, data, section);
      final isInRadius = touchR > centerRadius && touchR <= sectionRadius;

      /// degree criteria
      final space = data.sectionsSpace / 2;
      final fromDegree = tempAngle + space;
      final toDegree = sectionAngle + tempAngle - space;
      final isInDegree =
          relativeTouchAngle >= fromDegree && relativeTouchAngle <= toDegree;

      if (isInDegree && isInRadius) {
        foundSectionData = section;
        foundSectionDataPosition = i;
        break;
      }

      tempAngle += sectionAngle;
    }

    return PieTouchedSection(
      foundSectionData,
      foundSectionDataPosition,
      touchAngle,
      touchR,
    );
  }

  /// Exposes offset for laying out the badge widgets upon the chart.
  Map<int, Offset> getBadgeOffsets(
    Size viewSize,
    PaintHolder<PieChartData> holder,
  ) {
    final data = holder.data;
    final center = viewSize.center(Offset.zero);
    final badgeWidgetsOffsets = <int, Offset>{};

    if (data.sections.isEmpty) {
      return badgeWidgetsOffsets;
    }

    var tempAngle = data.startDegreeOffset;

    final sectionsAngle = calculateSectionsAngle(data.sections, data.sumValue);
    for (var i = 0; i < data.sections.length; i++) {
      final section = data.sections[i];
      final startAngle = tempAngle;
      final sweepAngle = sectionsAngle[i];

      final sectionRadius = calculateSectionRadius(viewSize, data, section);
      final sectionCenterAngle = startAngle + (sweepAngle / 2);
      final centerRadius = calculateCenterRadius(viewSize, holder);

      Offset sectionCenter(double percentageOffset) =>
          center +
          Offset(
            math.cos(Utils().radians(sectionCenterAngle)) *
                (centerRadius + (sectionRadius * percentageOffset)),
            math.sin(Utils().radians(sectionCenterAngle)) *
                (centerRadius + (sectionRadius * percentageOffset)),
          );

      final sectionCenterOffsetBadgeWidget =
          sectionCenter(section.badgePositionPercentageOffset);

      badgeWidgetsOffsets[i] = sectionCenterOffsetBadgeWidget;

      tempAngle += sweepAngle;
    }

    return badgeWidgetsOffsets;
  }
}
