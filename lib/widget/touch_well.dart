import 'package:flutter/material.dart';

class TouchWell extends StatefulWidget {
  final Widget child;
  final GestureTapCallback onTap;
  final GestureTapCallback onDoubleTap;
  final GestureLongPressCallback onLongPress;
  final GestureTapDownCallback onTapDown;
  final GestureTapCancelCallback onTapCancel;
  final ValueChanged<bool> onHighlightChanged;
  final ValueChanged<bool> onHover;
  final Color bgColor;
  final Color focusColor;
  final Color hoverColor;
  final Color highlightColor;
  final Color splashColor;
  final InteractiveInkFeatureFactory splashFactory;
  final double radius;
  final BorderRadius borderRadius;
  final ShapeBorder customBorder;
  final bool enableFeedback;
  final bool excludeFromSemantics;
  final FocusNode focusNode;
  final bool canRequestFocus;
  final ValueChanged<bool> onFocusChange;
  final bool autofocus;
  final bool circleBoard;
  final bool protectMultiTap;
  final bool touchWellIsTop;

  TouchWell({
    Key key,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapCancel,
    this.onHighlightChanged,
    this.onHover,
    this.bgColor = Colors.transparent,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.splashFactory,
    this.radius,
    this.borderRadius,
    this.customBorder,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.onFocusChange,
    this.autofocus = false,
    this.circleBoard = false,
    this.protectMultiTap = false,
    this.touchWellIsTop = false})
      : super(key: key);

  @override
  _TouchWellState createState() => _TouchWellState();
}

class _TouchWellState extends State<TouchWell> {
  int tapTimeMs;

  @override
  void initState() {
    super.initState();
    tapTimeMs = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    if(widget.touchWellIsTop) {
      return Stack(
        children: <Widget>[
          this.widget.child,
          Positioned.fill(child: _buildMaterial(null)),
        ],
      );
    } else {
      return _buildMaterial(this.widget.child);
    }
  }

  Material _buildMaterial(Widget child) {
    return Material(
      color: widget.bgColor,
      shape: widget.circleBoard ? CircleBorder() : null,
      clipBehavior: widget.circleBoard ? Clip.hardEdge : Clip.none,
      child: InkWell(
        onTap: widget.protectMultiTap ? widget.onTap != null ? () {
          final now = DateTime.now().millisecondsSinceEpoch;
          if(now - tapTimeMs > 500) {
            tapTimeMs = now;
            widget.onTap();
          }
        } : null : widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        onTapDown: widget.onTapDown,
        onTapCancel: widget.onTapCancel,
        onHighlightChanged: widget.onHighlightChanged,
        onHover: widget.onHover,
        focusColor: widget.focusColor,
        hoverColor: widget.hoverColor,
        highlightColor: widget.highlightColor,
        splashColor: widget.splashColor,
        splashFactory: widget.splashFactory,
        radius: widget.radius,
        borderRadius: widget.borderRadius,
        customBorder: widget.customBorder,
        enableFeedback: widget.enableFeedback,
        excludeFromSemantics: widget.excludeFromSemantics,
        focusNode: widget.focusNode,
        canRequestFocus: widget.canRequestFocus,
        onFocusChange: widget.onFocusChange,
        autofocus: widget.autofocus,
        child: child,
      ),
    );
  }
}