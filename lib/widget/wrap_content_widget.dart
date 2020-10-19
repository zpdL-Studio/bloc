import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class WrapContent extends SingleChildRenderObjectWidget {
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  WrapContent({
    Widget? child,
    required this.minWidth,
    required this.maxWidth,
    required this.minHeight,
    required this.maxHeight, Key? key}): super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _WrapContentRenderBox()
        .._minWidth = minWidth
        .._maxWidth = maxWidth
        .._minHeight = minHeight
        .._maxHeight = maxHeight;

  @override
  void updateRenderObject(BuildContext context, _WrapContentRenderBox renderObject) {
    renderObject
      ..minWidth = minWidth
      ..maxWidth = maxWidth
      ..minHeight = minHeight
      ..maxHeight = maxHeight
    ;
  }
}

class _WrapContentRenderBox extends RenderShiftedBox {

  _WrapContentRenderBox({
    RenderBox? child,
  })
      : super(child);

  double _minWidth = 0;
  double get minWidth => _minWidth;
  set minWidth(double minWidth) {
    if(_minWidth != minWidth) {
      _minWidth = minWidth;
      markNeedsLayout();
    }
  }

  double _maxWidth = double.infinity;
  double get maxWidth => _maxWidth;
  set maxWidth(double maxWidth) {
    if(_maxWidth != maxWidth) {
      _maxWidth = maxWidth;
      markNeedsLayout();
    }
  }

  double _minHeight = 0;
  double get minHeight => _minHeight;
  set minHeight(double minHeight) {
    if(_minHeight != minHeight) {
      _minHeight = minHeight;
      markNeedsLayout();
    }
  }

  double _maxHeight = double.infinity;
  double get maxHeight => _maxHeight;
  set maxHeight(double maxHeight) {
    if(_maxHeight != maxHeight) {
      _maxHeight = maxHeight;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    var minW = _minWidth > constraints.minWidth ? _minWidth : constraints
        .minWidth;
    var maxW = _maxWidth < constraints.maxWidth ? _maxWidth : constraints
        .maxWidth;
    var minH = _minHeight > constraints.minHeight ? _minHeight : constraints
        .minHeight;
    var maxH = _maxHeight < constraints.maxHeight ? _maxHeight : constraints
        .maxHeight;

    var child = this.child;
    if (child != null) {
      child.layout(BoxConstraints(
        minWidth: 0,
        maxWidth: maxW,
        minHeight: 0,
        maxHeight: maxH,
      ), parentUsesSize: true);

      var width = child.size.width;
      if(width < minW) {
        width = minW;
      }
      var height = child.size.height;
      if(height < minH) {
        height = minH;
      }

      size = Size(width, height);
      if(child.parentData is BoxParentData) {
        final childParentData = child.parentData as BoxParentData;
        childParentData.offset = Offset((width - child.size.width) / 2, (height - child.size.height) / 2);
      }
    }
  }
}