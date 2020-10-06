import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class WrapContent extends SingleChildRenderObjectWidget {
  final Key key;
  final Widget child;

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  WrapContent({
    this.key,
    this.child,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight, }): super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _WrapContentRenderBox(
          minWidth: minWidth,
          maxWidth: maxWidth,
          minHeight: minHeight,
          maxHeight: maxHeight
      );

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
    double minWidth,
    double maxWidth,
    double minHeight,
    double maxHeight,
    RenderBox child,
  })
      : super(child);

  double _minWidth;
  double get minWidth => _minWidth;
  set minWidth(double minWidth) {
    if(_minWidth != minWidth) {
      _minWidth = minWidth;
      markNeedsLayout();
    }
  }

  double _maxWidth;
  double get maxWidth => _maxWidth;
  set maxWidth(double maxWidth) {
    if(_maxWidth != maxWidth) {
      _maxWidth = maxWidth;
      markNeedsLayout();
    }
  }

  double _minHeight;
  double get minHeight => _minHeight;
  set minHeight(double minHeight) {
    if(_minHeight != minHeight) {
      _minHeight = minHeight;
      markNeedsLayout();
    }
  }

  double _maxHeight;
  double get maxHeight => _maxHeight;
  set maxHeight(double maxHeight) {
    if(_maxHeight != maxHeight) {
      _maxHeight = maxHeight;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    if(child != null && constraints != null) {
      double minW = minWidth != null
          ? minWidth < constraints.maxWidth ? minWidth : constraints.maxWidth
          : constraints.minWidth;
      double maxW = maxWidth != null
          ? maxWidth < constraints.maxWidth ? maxWidth : constraints.maxWidth
          : constraints.maxWidth;
      double minH = minHeight != null
          ? minHeight < constraints.maxHeight ? minHeight : constraints.maxHeight
          : constraints.minHeight;
      double maxH = maxHeight != null
          ? maxHeight < constraints.maxHeight ? maxHeight : constraints.maxHeight
          : constraints.maxHeight;

      child.layout(BoxConstraints(
        minWidth: 0,
        maxWidth: maxW,
        minHeight: 0,
        maxHeight: maxH,
      ), parentUsesSize: true);

      double width = child.size.width;
      if(width < minW) {
        width = minW;
      }
      double height = child.size.height;
      if(height < minH) {
        height = minH;
      }

      size = Size(width, height);
      if(child.parentData is BoxParentData) {
        final BoxParentData childParentData = child.parentData;
        childParentData.offset = Offset((width - child.size.width) / 2, (height - child.size.height) / 2);
      }
    }
  }
}