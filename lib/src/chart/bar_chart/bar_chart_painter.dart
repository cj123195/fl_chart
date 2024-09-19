import 'dart:core';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_painter.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/extensions/bar_chart_data_extension.dart';
import 'package:fl_chart/src/extensions/paint_extension.dart';
import 'package:fl_chart/src/extensions/path_extension.dart';
import 'package:fl_chart/src/extensions/rrect_extension.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:flutter/material.dart';

/// Paints [BarChartData] in the canvas, it can be used in a [CustomPainter]
class BarChartPainter extends AxisChartPainter<BarChartData> {
  /// Paints [dataList] into canvas, it is the animating [BarChartData],
  /// [targetData] is the animation's target and remains the same
  /// during animation, then we should use it  when we need to show
  /// tooltips or something like that, because [dataList] is changing constantly.
  ///
  /// [textScale] used for scaling texts inside the chart,
  /// parent can use [MediaQuery.textScaleFactor] to respect
  /// the system's font size.
  BarChartPainter() : super() {
    _barPaint = Paint()..style = PaintingStyle.fill;
    _barStrokePaint = Paint()..style = PaintingStyle.stroke;

    _bgTouchTooltipPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    _borderTouchTooltipPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.transparent
      ..strokeWidth = 1.0;
  }

  late Paint _barPaint;
  late Paint _barStrokePaint;
  late Paint _bgTouchTooltipPaint;
  late Paint _borderTouchTooltipPaint;

  List<GroupBarsPosition>? _groupBarsPosition;

  /// Paints [BarChartData] into the provided canvas.
  @override
  void paint(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<BarChartData> holder, [
    BaseTouchResponse? touchResponse,
  ]) {
    super.paint(context, canvasWrapper, holder);
    final data = holder.data;
    final targetData = holder.targetData;

    if (data.barGroups.isEmpty) {
      return;
    }

    final groupsX = data.calculateGroupsX(
      data.direction == Axis.vertical
          ? canvasWrapper.size.width
          : canvasWrapper.size.height,
    );
    _groupBarsPosition = calculateGroupAndBarsPosition(
      canvasWrapper.size,
      groupsX,
      data.barGroups,
    );

    if (!data.extraLinesData.extraLinesOnTop) {
      super.drawHorizontalLines(
        context,
        canvasWrapper,
        holder,
        canvasWrapper.size,
      );
    }

    drawBars(canvasWrapper, _groupBarsPosition!, holder);

    if (data.extraLinesData.extraLinesOnTop) {
      super.drawHorizontalLines(
        context,
        canvasWrapper,
        holder,
        canvasWrapper.size,
      );
    }

    for (var i = 0; i < targetData.barGroups.length; i++) {
      final barGroup = targetData.barGroups[i];
      for (var j = 0; j < barGroup.barRods.length; j++) {
        if (!barGroup.showingTooltipIndicators.contains(j)) {
          continue;
        }
        final barRod = barGroup.barRods[j];

        drawTouchTooltip(
          context,
          canvasWrapper,
          _groupBarsPosition!,
          targetData.barTouchData.touchTooltipData,
          barGroup,
          i,
          barRod,
          j,
          holder,
        );
      }
    }
  }

  /// Calculates bars position alongside group positions.
  @visibleForTesting
  List<GroupBarsPosition> calculateGroupAndBarsPosition(
    Size viewSize,
    List<double> groupsX,
    List<BarChartGroupData> barGroups,
  ) {
    if (groupsX.length != barGroups.length) {
      throw Exception('inconsistent state groupsX.length != barGroups.length');
    }

    final groupBarsPosition = <GroupBarsPosition>[];
    for (var i = 0; i < barGroups.length; i++) {
      final barGroup = barGroups[i];
      final groupX = groupsX[i];
      if (barGroup.groupVertically) {
        groupBarsPosition.add(
          GroupBarsPosition(
            groupX,
            List.generate(barGroup.barRods.length, (index) => groupX),
          ),
        );
        continue;
      }

      var tempX = 0.0;
      final barsX = <double>[];
      barGroup.barRods.asMap().forEach((barIndex, barRod) {
        final widthHalf = barRod.width / 2;
        barsX.add(groupX - (barGroup.width / 2) + tempX + widthHalf);
        tempX += barRod.width + barGroup.barsSpace;
      });
      groupBarsPosition.add(GroupBarsPosition(groupX, barsX));
    }
    return groupBarsPosition;
  }

  @visibleForTesting
  void drawBars(
    CanvasWrapper canvasWrapper,
    List<GroupBarsPosition> groupBarsPosition,
    PaintHolder<BarChartData> holder,
  ) {
    final data = holder.data;
    final viewSize = canvasWrapper.size;

    for (var i = 0; i < data.barGroups.length; i++) {
      final barGroup = data.barGroups[i];
      for (var j = 0; j < barGroup.barRods.length; j++) {
        final barRod = barGroup.barRods[j];
        final widthHalf = barRod.width / 2;
        final borderRadius = barRod.borderRadius;
        final borderSide = barRod.borderSide;

        final x = groupBarsPosition[i].barsX[j];

        if (data.direction == Axis.vertical) {
          drawVerticalBar(
            viewSize,
            data,
            holder,
            canvasWrapper,
            barRod,
            widthHalf,
            borderRadius,
            borderSide,
            x,
          );
        } else {
          drawHorizontalBar(
            viewSize,
            data,
            holder,
            canvasWrapper,
            barRod,
            widthHalf,
            borderRadius,
            borderSide,
            x,
          );
        }
      }
    }
  }

  void drawVerticalBar(
    Size viewSize,
    BarChartData data,
    PaintHolder<BarChartData> holder,
    CanvasWrapper canvasWrapper,
    BarChartRodData barRod,
    double widthHalf,
    BorderRadius? borderRadius,
    BorderSide borderSide,
    double x,
  ) {
    final left = x - widthHalf;
    final right = x + widthHalf;

    double getCornerHeight(BorderRadius borderRadius) {
      return max(borderRadius.topLeft.y, borderRadius.topRight.y) +
          max(borderRadius.bottomLeft.y, borderRadius.bottomRight.y);
    }

    RRect barRRect;

    /// Draw [BackgroundBarChartRodData]
    if (barRod.backDrawRodData.show &&
        barRod.backDrawRodData.to != barRod.backDrawRodData.from) {
      if (barRod.backDrawRodData.to > barRod.backDrawRodData.from) {
        // positive
        borderRadius ??=
            BorderRadius.vertical(top: Radius.circular(barRod.width / 2));
        final bottom = getPixelY(
          max(data.minY, barRod.backDrawRodData.from),
          viewSize,
          holder,
        );
        final top = min(
          getPixelY(barRod.backDrawRodData.to, viewSize, holder),
          bottom - getCornerHeight(borderRadius),
        );

        barRRect = RRect.fromLTRBAndCorners(
          left,
          top,
          right,
          bottom,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
      } else {
        // negative
        borderRadius ??= BorderRadius.vertical(
          bottom: Radius.circular(barRod.width / 2),
        );
        final top = getPixelY(
          min(data.maxY, barRod.backDrawRodData.from),
          viewSize,
          holder,
        );
        final bottom = max(
          getPixelY(barRod.backDrawRodData.to, viewSize, holder),
          top + getCornerHeight(borderRadius),
        );

        barRRect = RRect.fromLTRBAndCorners(
          left,
          top,
          right,
          bottom,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
      }

      final backDraw = barRod.backDrawRodData;
      _barPaint.setColorOrGradient(
        backDraw.color,
        backDraw.gradient,
        barRRect.getRect(),
      );
      canvasWrapper.drawRRect(barRRect, _barPaint);
    }

    // draw Main Rod
    if (barRod.to != barRod.from) {
      if (barRod.to > barRod.from) {
        // positive
        borderRadius ??=
            BorderRadius.vertical(top: Radius.circular(barRod.width / 2));
        final bottom = getPixelY(max(data.minY, barRod.from), viewSize, holder);
        final top = min(
          getPixelY(barRod.to, viewSize, holder),
          bottom - getCornerHeight(borderRadius),
        );

        barRRect = RRect.fromLTRBAndCorners(
          left,
          top,
          right,
          bottom,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
      } else {
        // negative

        borderRadius ??=
            BorderRadius.vertical(top: Radius.circular(barRod.width / 2));
        final top = getPixelY(min(data.maxY, barRod.from), viewSize, holder);
        final bottom = max(
          getPixelY(barRod.to, viewSize, holder),
          top + getCornerHeight(borderRadius),
        );

        barRRect = RRect.fromLTRBAndCorners(
          left,
          top,
          right,
          bottom,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
      }
      _barPaint.setColorOrGradient(
        barRod.color,
        barRod.gradient,
        barRRect.getRect(),
      );
      canvasWrapper.drawRRect(barRRect, _barPaint);

      // draw rod stack
      if (barRod.rodStackItems.isNotEmpty) {
        for (var i = 0; i < barRod.rodStackItems.length; i++) {
          final stackItem = barRod.rodStackItems[i];
          final stackFromY = getPixelY(stackItem.from, viewSize, holder);
          final stackToY = getPixelY(stackItem.to, viewSize, holder);

          final isNegative = stackItem.to < stackItem.from;
          _barPaint.color = stackItem.color;
          final rect = isNegative
              ? Rect.fromLTRB(left, stackFromY, right, stackToY)
              : Rect.fromLTRB(left, stackToY, right, stackFromY);
          canvasWrapper
            ..save()
            ..clipRect(rect)
            ..drawRRect(barRRect, _barPaint)
            ..restore();

          // draw border stroke for each stack item
          drawStackItemBorderStroke(
            canvasWrapper,
            stackItem,
            i,
            barRod.rodStackItems.length,
            barRod.width,
            barRRect,
            viewSize,
            holder,
          );
        }
      }

      // draw border stroke
      if (borderSide.width > 0 && borderSide.color.opacity > 0) {
        _barStrokePaint
          ..color = borderSide.color
          ..strokeWidth = borderSide.width;

        final borderPath = Path()..addRRect(barRRect);

        canvasWrapper.drawPath(
          borderPath.toDashedPath(
            barRod.borderDashArray,
          ),
          _barStrokePaint,
        );
      }
    }
  }

  void drawHorizontalBar(
    Size viewSize,
    BarChartData data,
    PaintHolder<BarChartData> holder,
    CanvasWrapper canvasWrapper,
    BarChartRodData barRod,
    double widthHalf,
    BorderRadius? borderRadius,
    BorderSide borderSide,
    double y,
  ) {
    final top = y - widthHalf;
    final bottom = y + widthHalf;

    double getCornerHeight(BorderRadius borderRadius) {
      return max(borderRadius.topLeft.x, borderRadius.topRight.x) +
          max(borderRadius.bottomLeft.x, borderRadius.bottomRight.x);
    }

    final radius = Radius.circular(widthHalf);

    RRect barRRect;

    /// Draw [BackgroundBarChartRodData]
    if (barRod.backDrawRodData.show &&
        barRod.backDrawRodData.to != barRod.backDrawRodData.from) {
      if (barRod.backDrawRodData.to > barRod.backDrawRodData.from) {
        // positive
        borderRadius ??= BorderRadius.horizontal(right: radius);
        final left = getPixelX(
          min(data.minX, barRod.backDrawRodData.from),
          viewSize,
          holder,
        );
        final right = max(
          getPixelX(barRod.backDrawRodData.to, viewSize, holder),
          left + getCornerHeight(borderRadius),
        );

        barRRect = RRect.fromLTRBAndCorners(
          left,
          top,
          right,
          bottom,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
      } else {
        // negative
        borderRadius ??= BorderRadius.horizontal(left: radius);
        final right = getPixelX(
          max(data.maxX, barRod.backDrawRodData.from),
          viewSize,
          holder,
        );
        final left = min(
          getPixelX(barRod.backDrawRodData.to, viewSize, holder),
          right - getCornerHeight(borderRadius),
        );

        barRRect = RRect.fromLTRBAndCorners(
          left,
          top,
          right,
          bottom,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
      }

      final backDraw = barRod.backDrawRodData;
      _barPaint.setColorOrGradient(
        backDraw.color,
        backDraw.gradient,
        barRRect.getRect(),
      );
      canvasWrapper.drawRRect(barRRect, _barPaint);
    }

    // draw Main Rod
    if (barRod.to != barRod.from) {
      if (barRod.to > barRod.from) {
        // positive
        borderRadius ??= BorderRadius.horizontal(right: radius);
        final left = getPixelX(max(data.minX, barRod.from), viewSize, holder);
        final right = max(
          getPixelX(barRod.to, viewSize, holder),
          left + getCornerHeight(borderRadius),
        );

        barRRect = RRect.fromLTRBAndCorners(
          left,
          top,
          right,
          bottom,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
      } else {
        // negative
        borderRadius ??= BorderRadius.horizontal(left: radius);
        final right = getPixelX(min(data.maxX, barRod.from), viewSize, holder);
        final left = min(
          getPixelY(barRod.to, viewSize, holder),
          right - getCornerHeight(borderRadius),
        );

        barRRect = RRect.fromLTRBAndCorners(
          left,
          top,
          right,
          bottom,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
      }
      _barPaint.setColorOrGradient(
        barRod.color,
        barRod.gradient,
        barRRect.getRect(),
      );
      canvasWrapper.drawRRect(barRRect, _barPaint);

      // draw rod stack
      if (barRod.rodStackItems.isNotEmpty) {
        for (var i = 0; i < barRod.rodStackItems.length; i++) {
          final stackItem = barRod.rodStackItems[i];
          final stackFromX = getPixelX(stackItem.from, viewSize, holder);
          final stackToX = getPixelX(stackItem.to, viewSize, holder);

          final isNegative = stackItem.to < stackItem.from;
          _barPaint.color = stackItem.color;
          final rect = isNegative
              ? Rect.fromLTRB(stackFromX, top, stackToX, bottom)
              : Rect.fromLTRB(stackToX, top, stackFromX, bottom);
          canvasWrapper
            ..save()
            ..clipRect(rect)
            ..drawRRect(barRRect, _barPaint)
            ..restore();

          // draw border stroke for each stack item
          drawStackItemBorderStroke(
            canvasWrapper,
            stackItem,
            i,
            barRod.rodStackItems.length,
            barRod.width,
            barRRect,
            viewSize,
            holder,
          );
        }
      }

      // draw border stroke
      if (borderSide.width > 0 && borderSide.color.opacity > 0) {
        _barStrokePaint
          ..color = borderSide.color
          ..strokeWidth = borderSide.width;

        final borderPath = Path()..addRRect(barRRect);

        canvasWrapper.drawPath(
          borderPath.toDashedPath(
            barRod.borderDashArray,
          ),
          _barStrokePaint,
        );
      }
    }
  }

  @visibleForTesting
  void drawTouchTooltip(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    List<GroupBarsPosition> groupPositions,
    BarTouchTooltipData tooltipData,
    BarChartGroupData showOnBarGroup,
    int barGroupIndex,
    BarChartRodData showOnRodData,
    int barRodIndex,
    PaintHolder<BarChartData> holder,
  ) {
    final viewSize = canvasWrapper.size;

    const textsBelowMargin = 0;

    final tooltipItem = tooltipData.getTooltipItem(
      showOnBarGroup,
      barGroupIndex,
      showOnRodData,
      barRodIndex,
    );

    if (tooltipItem == null) {
      return;
    }

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
    final tooltipWidth = textWidth + tooltipData.tooltipPadding.horizontal;
    final tooltipHeight = textHeight + tooltipData.tooltipPadding.vertical;

    /// draw the background rect with rounded radius
    // ignore: omit_local_variable_types
    final x = groupPositions[barGroupIndex].barsX[barRodIndex];
    var rect = holder.targetData.direction == Axis.vertical
        ? getVerticalTooltipRect(
            holder,
            viewSize,
            showOnRodData,
            tooltipData,
            tooltipItem,
            tooltipWidth,
            tooltipHeight,
            x,
          )
        : getHorizontalTooltipRect(
            holder,
            viewSize,
            showOnRodData,
            tooltipData,
            tooltipItem,
            tooltipWidth,
            tooltipHeight,
            x,
          );

    if (tooltipData.fitInsideHorizontally) {
      if (rect.left < 0) {
        final shiftAmount = 0 - rect.left;
        rect = Rect.fromLTRB(
          rect.left + shiftAmount,
          rect.top,
          rect.right + shiftAmount,
          rect.bottom,
        );
      }

      if (rect.right > viewSize.width) {
        final shiftAmount = rect.right - viewSize.width;
        rect = Rect.fromLTRB(
          rect.left - shiftAmount,
          rect.top,
          rect.right - shiftAmount,
          rect.bottom,
        );
      }
    }

    if (tooltipData.fitInsideVertically) {
      if (rect.top < 0) {
        final shiftAmount = 0 - rect.top;
        rect = Rect.fromLTRB(
          rect.left,
          rect.top + shiftAmount,
          rect.right,
          rect.bottom + shiftAmount,
        );
      }

      if (rect.bottom > viewSize.height) {
        final shiftAmount = rect.bottom - viewSize.height;
        rect = Rect.fromLTRB(
          rect.left,
          rect.top - shiftAmount,
          rect.right,
          rect.bottom - shiftAmount,
        );
      }
    }

    final radius = Radius.circular(tooltipData.tooltipRoundedRadius);
    final roundedRect = RRect.fromRectAndCorners(
      rect,
      topLeft: radius,
      topRight: radius,
      bottomLeft: radius,
      bottomRight: radius,
    );

    /// set tooltip's background color for each rod
    _bgTouchTooltipPaint.color = tooltipData.getTooltipColor == null
        ? Theme.of(context).colorScheme.background
        : tooltipData.getTooltipColor!(showOnBarGroup);

    final rotateAngle = tooltipData.rotateAngle;
    final rectRotationOffset = Offset(
      0,
      Utils().calculateRotationOffset(rect.size, rotateAngle).dy,
    );
    final rectDrawOffset = Offset(roundedRect.left, roundedRect.top);

    final textRotationOffset =
        Utils().calculateRotationOffset(tp.size, rotateAngle);

    /// draw the texts one by one in below of each other
    final top = tooltipData.tooltipPadding.top;
    final drawOffset = Offset(
      rect.center.dx - (innerWidth / 2),
      rect.topCenter.dy + top - textRotationOffset.dy + rectRotationOffset.dy,
    );

    if (tooltipData.tooltipBorder != BorderSide.none) {
      _borderTouchTooltipPaint
        ..color = tooltipData.tooltipBorder.color
        ..strokeWidth = tooltipData.tooltipBorder.width;
    }

    canvasWrapper.drawRotated(
      size: rect.size,
      rotationOffset: rectRotationOffset,
      drawOffset: rectDrawOffset,
      angle: rotateAngle,
      drawCallback: () {
        canvasWrapper
          ..drawRRect(roundedRect, _bgTouchTooltipPaint)
          ..drawRRect(roundedRect, _borderTouchTooltipPaint);
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

  Rect getVerticalTooltipRect(
    PaintHolder<BarChartData> holder,
    Size viewSize,
    BarChartRodData showOnRodData,
    BarTouchTooltipData tooltipData,
    BarTooltipItem tooltipItem,
    double tooltipWidth,
    double tooltipHeight,
    double dx,
  ) {
    final barToYPixel = Offset(
      dx,
      getPixelY(showOnRodData.to, viewSize, holder),
    );

    final barFromYPixel = Offset(
      dx,
      getPixelY(showOnRodData.from, viewSize, holder),
    );

    final barTopY = min(barToYPixel.dy, barFromYPixel.dy);
    final barBottomY = max(barToYPixel.dy, barFromYPixel.dy);
    final drawTooltipOnTop = tooltipData.direction == TooltipDirection.top ||
        (tooltipData.direction == TooltipDirection.auto &&
            showOnRodData.isUpward());
    final tooltipTop = drawTooltipOnTop
        ? barTopY - tooltipHeight - tooltipData.tooltipMargin
        : barBottomY + tooltipData.tooltipMargin;

    final tooltipLeft = getTooltipLeft(
      barToYPixel.dx,
      tooltipWidth,
      tooltipData.tooltipHorizontalAlignment,
      tooltipData.tooltipHorizontalOffset,
    );

    /// draw the background rect with rounded radius
    // ignore: omit_local_variable_types
    return Rect.fromLTWH(
      tooltipLeft,
      tooltipTop,
      tooltipWidth,
      tooltipHeight,
    );
  }

  Rect getHorizontalTooltipRect(
    PaintHolder<BarChartData> holder,
    Size viewSize,
    BarChartRodData showOnRodData,
    BarTouchTooltipData tooltipData,
    BarTooltipItem tooltipItem,
    double tooltipWidth,
    double tooltipHeight,
    double dy,
  ) {
    final barToXPixel = Offset(
      getPixelX(showOnRodData.to, viewSize, holder),
      dy,
    );

    final barFromXPixel = Offset(
      getPixelX(showOnRodData.from, viewSize, holder),
      dy,
    );

    final barRightY = max(barToXPixel.dx, barFromXPixel.dx);

    final tooltipTop = dy - tooltipHeight / 2;

    final tooltipLeft = barRightY + tooltipData.tooltipMargin;

    /// draw the background rect with rounded radius
    // ignore: omit_local_variable_types
    return Rect.fromLTWH(
      tooltipLeft,
      tooltipTop,
      tooltipWidth,
      tooltipHeight,
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

  @visibleForTesting
  void drawStackItemBorderStroke(
    CanvasWrapper canvasWrapper,
    BarChartRodStackItem stackItem,
    int index,
    int rodStacksSize,
    double barThickSize,
    RRect barRRect,
    Size drawSize,
    PaintHolder<BarChartData> holder,
  ) {
    if (stackItem.borderSide.width == 0 ||
        stackItem.borderSide.color.opacity == 0) return;
    RRect strokeBarRect;
    if (index == 0) {
      strokeBarRect = RRect.fromLTRBAndCorners(
        barRRect.left,
        getPixelY(stackItem.to, drawSize, holder),
        barRRect.right,
        getPixelY(stackItem.from, drawSize, holder),
        bottomLeft:
            stackItem.from < stackItem.to ? barRRect.blRadius : Radius.zero,
        bottomRight:
            stackItem.from < stackItem.to ? barRRect.brRadius : Radius.zero,
        topLeft:
            stackItem.from < stackItem.to ? Radius.zero : barRRect.tlRadius,
        topRight:
            stackItem.from < stackItem.to ? Radius.zero : barRRect.trRadius,
      );
    } else if (index == rodStacksSize - 1) {
      strokeBarRect = RRect.fromLTRBAndCorners(
        barRRect.left,
        max(getPixelY(stackItem.to, drawSize, holder), barRRect.top),
        barRRect.right,
        getPixelY(stackItem.from, drawSize, holder),
        bottomLeft:
            stackItem.from < stackItem.to ? Radius.zero : barRRect.blRadius,
        bottomRight:
            stackItem.from < stackItem.to ? Radius.zero : barRRect.brRadius,
        topLeft:
            stackItem.from < stackItem.to ? barRRect.tlRadius : Radius.zero,
        topRight:
            stackItem.from < stackItem.to ? barRRect.trRadius : Radius.zero,
      );
    } else {
      strokeBarRect = RRect.fromLTRBR(
        barRRect.left,
        getPixelY(stackItem.to, drawSize, holder),
        barRRect.right,
        getPixelY(stackItem.from, drawSize, holder),
        Radius.zero,
      );
    }
    _barStrokePaint
      ..color = stackItem.borderSide.color
      ..strokeWidth = min(stackItem.borderSide.width, barThickSize / 2);
    canvasWrapper.drawRRect(strokeBarRect, _barStrokePaint);
  }

  /// Makes a [BarTouchedSpot] based on the provided [localPosition]
  ///
  /// Processes [localPosition] and checks
  /// the elements of the chart that are near the offset,
  /// then makes a [BarTouchedSpot] from the elements that has been touched.
  ///
  /// Returns null if finds nothing!
  BarTouchedSpot? handleTouch(
    Offset localPosition,
    Size viewSize,
    PaintHolder<BarChartData> holder,
  ) {
    final data = holder.data;
    final targetData = holder.targetData;
    final touchedPoint = localPosition;
    if (targetData.barGroups.isEmpty) {
      return null;
    }

    if (_groupBarsPosition == null) {
      final groupsX = data.calculateGroupsX(
        data.direction == Axis.vertical ? viewSize.width : viewSize.height,
      );
      _groupBarsPosition =
          calculateGroupAndBarsPosition(viewSize, groupsX, data.barGroups);
    }

    /// Find the nearest barRod
    for (var i = 0; i < _groupBarsPosition!.length; i++) {
      final groupBarPos = _groupBarsPosition![i];
      for (var j = 0; j < groupBarPos.barsX.length; j++) {
        final barX = groupBarPos.barsX[j];
        final barRod = targetData.barGroups[i].barRods[j];
        final halfBarWidth = barRod.width / 2;

        final isXInTouchBounds = _isXInTouchBounds(
          holder,
          viewSize,
          targetData.barGroups[i].barRods[j],
          touchedPoint,
          barX,
          halfBarWidth,
        );
        final isYInTouchBounds = _isYInTouchBounds(
          holder,
          viewSize,
          barRod,
          touchedPoint,
          barX,
          halfBarWidth,
        );

        if (isXInTouchBounds && isYInTouchBounds) {
          final nearestGroup = targetData.barGroups[i];
          final nearestBarRod = nearestGroup.barRods[j];
          final nearestSpot =
              FlSpot(nearestGroup.index.toDouble(), nearestBarRod.to);
          final nearestSpotPos =
              Offset(barX, getPixelY(nearestSpot.y, viewSize, holder));

          var touchedStackIndex = -1;
          BarChartRodStackItem? touchedStack;
          for (var stackIndex = 0;
              stackIndex < nearestBarRod.rodStackItems.length;
              stackIndex++) {
            final stackItem = nearestBarRod.rodStackItems[stackIndex];
            final fromPixel = getPixelY(stackItem.from, viewSize, holder);
            final toPixel = getPixelY(stackItem.to, viewSize, holder);
            if (touchedPoint.dy <= fromPixel && touchedPoint.dy >= toPixel) {
              touchedStackIndex = stackIndex;
              touchedStack = stackItem;
              break;
            }
          }

          return BarTouchedSpot(
            nearestGroup,
            i,
            nearestBarRod,
            j,
            touchedStack,
            touchedStackIndex,
            nearestSpot,
            nearestSpotPos,
          );
        }
      }
    }

    return null;
  }

  bool _isXInTouchBounds(
    PaintHolder<BarChartData> holder,
    Size viewSize,
    BarChartRodData barRod,
    Offset touchedPoint,
    double barX,
    double halfBarWidth,
  ) {
    final targetData = holder.targetData;
    final touchExtraThreshold = targetData.barTouchData.touchExtraThreshold;

    if (targetData.direction == Axis.vertical) {
      return (touchedPoint.dx <=
              barX + halfBarWidth + touchExtraThreshold.right) &&
          (touchedPoint.dx >= barX - halfBarWidth - touchExtraThreshold.left);
    }

    double barLeftX;
    double barRightX;

    final isUpward = barRod.isUpward();
    if (isUpward) {
      barRightX = getPixelX(barRod.to, viewSize, holder);
      barLeftX = getPixelX(
        barRod.from - barRod.backDrawRodData.from,
        viewSize,
        holder,
      );
    } else {
      barRightX = getPixelX(
        barRod.from + barRod.backDrawRodData.from,
        viewSize,
        holder,
      );
      barLeftX = getPixelX(barRod.to, viewSize, holder);
    }

    final backDrawBarX = getPixelX(
      barRod.backDrawRodData.to,
      viewSize,
      holder,
    );

    final isXInBarBounds =
        (touchedPoint.dx >= barLeftX - touchExtraThreshold.left) &&
            (touchedPoint.dx <= barRightX + touchExtraThreshold.right);

    bool isXInBarBackDrawBounds;
    if (isUpward) {
      isXInBarBackDrawBounds =
          (touchedPoint.dx >= barLeftX - touchExtraThreshold.left) &&
              (touchedPoint.dx >= backDrawBarX + touchExtraThreshold.right);
    } else {
      isXInBarBackDrawBounds =
          (touchedPoint.dx <= barRightX + touchExtraThreshold.right) &&
              (touchedPoint.dy >= backDrawBarX - touchExtraThreshold.left);
    }

    return (targetData.barTouchData.allowTouchBarBackDraw &&
            isXInBarBackDrawBounds) ||
        isXInBarBounds;
  }

  bool _isYInTouchBounds(
    PaintHolder<BarChartData> holder,
    Size viewSize,
    BarChartRodData barRod,
    Offset touchedPoint,
    double barY,
    double halfBarWidth,
  ) {
    final targetData = holder.targetData;
    final touchExtraThreshold = targetData.barTouchData.touchExtraThreshold;

    if (targetData.direction == Axis.horizontal) {
      return (touchedPoint.dy >=
              barY - halfBarWidth - touchExtraThreshold.top) &&
          (touchedPoint.dy <= barY + halfBarWidth + touchExtraThreshold.bottom);
    }

    double barTopY;
    double barBotY;

    final isUpward = barRod.isUpward();
    if (isUpward) {
      barTopY = getPixelY(barRod.to, viewSize, holder);
      barBotY = getPixelY(
        barRod.from + barRod.backDrawRodData.from,
        viewSize,
        holder,
      );
    } else {
      barTopY = getPixelY(
        barRod.from + barRod.backDrawRodData.from,
        viewSize,
        holder,
      );
      barBotY = getPixelY(barRod.to, viewSize, holder);
    }

    final backDrawBarY = getPixelY(
      barRod.backDrawRodData.to,
      viewSize,
      holder,
    );

    bool isYInBarBounds;
    if (isUpward) {
      isYInBarBounds =
          (touchedPoint.dy <= barBotY + touchExtraThreshold.bottom) &&
              (touchedPoint.dy >= barTopY - touchExtraThreshold.top);
    } else {
      isYInBarBounds = (touchedPoint.dy >= barTopY - touchExtraThreshold.top) &&
          (touchedPoint.dy <= barBotY + touchExtraThreshold.bottom);
    }

    bool isYInBarBackDrawBounds;
    if (isUpward) {
      isYInBarBackDrawBounds =
          (touchedPoint.dy <= barBotY + touchExtraThreshold.bottom) &&
              (touchedPoint.dy >= backDrawBarY - touchExtraThreshold.top);
    } else {
      isYInBarBackDrawBounds =
          (touchedPoint.dy >= barTopY - touchExtraThreshold.top) &&
              (touchedPoint.dy <= backDrawBarY + touchExtraThreshold.bottom);
    }

    return (targetData.barTouchData.allowTouchBarBackDraw &&
            isYInBarBackDrawBounds) ||
        isYInBarBounds;
  }
}

@visibleForTesting
class GroupBarsPosition {
  GroupBarsPosition(this.groupX, this.barsX);

  final double groupX;
  final List<double> barsX;
}
