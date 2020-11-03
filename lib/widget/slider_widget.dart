import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SliderHandler {
  final double width;
  final double height;
  final double activeScale;
  final Widget child;

  SliderHandler({this.width, this.height, this.activeScale, this.child});

}

enum SliderType {
  NORMAL,
  CENTER,
}

/*
SliderWidget(
  type: SliderType.CENTER,
  height: 44,
  bg: Container(height: 2, color: Colors.black12),
  fg: Container(height: 2, color: Colors.yellow),
  handler: SliderHandler(
    width: 44,
    height: 44,
    activeScale: 1.2,
    child: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.lightBlue,
        borderRadius: BorderRadius.circular(26 / 2)
      ),
    )
  ),
  min: 0,
  max: 1,
  value: 0.5,
  onDragStart: () {
  },
  onDragUpdate: (value) {
  },
  onDragEnd: () {
  },
);
 */
class SliderWidget extends StatefulWidget {

  const SliderWidget({
    Key key,
    this.type = SliderType.NORMAL,
    this.width,
    this.height,
    this.bg,
    this.fg,
    @required this.handler,
    this.min = 0.0,
    this.max = 1.0,
    this.value = 0.0,
    this.onDragStart,
    @required this.onDragUpdate,
    this.onDragEnd}) : super(key: key);

  final SliderType type;
  final double width;
  final double height;
  final Widget bg;
  final Widget fg;
  final SliderHandler handler;
  final double min;
  final double max;
  final double value;
  final Function() onDragStart;
  final Function(double value) onDragUpdate;
  final Function() onDragEnd;

  @override
  State<StatefulWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  GlobalKey _handlerGlobalKey = GlobalKey();

  bool _isDragging = false;
  double _value = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(!_isDragging) {
      _value = widget.value;
    }

    return Container(
      width: widget.width != null ? widget.width : double.infinity,
      height: widget.height != null ? widget.height : double.infinity,
      child: CustomMultiChildLayout(
        delegate: _SCSliderLayoutDelegate(widget.type, widget.min, widget.max, _value),
        children: <Widget>[
          if(widget.bg != null) LayoutId(id: _SliderIds.bg, child: widget.bg),
          if(widget.fg != null) LayoutId(id: _SliderIds.fg, child: widget.fg),
          LayoutId(id: _SliderIds.handler,
              child: Container(
                key: _handlerGlobalKey,
                width: widget.handler.width,
                height: widget.handler.height,
                alignment: Alignment.center,
                child: Transform.scale(
                    scale: _isDragging && widget.handler.activeScale != null ? widget.handler.activeScale : 1.0,
                    child: widget.handler.child),
              )
          ),
          if(widget.onDragUpdate != null) LayoutId(id: _SliderIds.drag, child: _HorizontalDragWidget(
            dragStart: (Offset localPosition) {
              RenderBox renderBoxBar = _handlerGlobalKey.currentContext.findRenderObject();
              final MultiChildLayoutParentData childParentData = renderBoxBar.parentData;
//            print("_HorizontalDragBackground details.localPosition ${details.localPosition}");
//            print("_HorizontalDragBackground childParentData.offset ${childParentData.offset}");
//            print("_HorizontalDragBackground renderBoxBar.size ${renderBoxBar.size}");
              final result =  localPosition.dx > childParentData.offset.dx
                  && localPosition.dx < childParentData.offset.dx + renderBoxBar.size.width
                  && localPosition.dy > childParentData.offset.dy
                  && localPosition.dy < childParentData.offset.dy + renderBoxBar.size.height;

              if(result) {
                double centerWidth = childParentData.offset.dx - localPosition.dx;
                if(widget.onDragStart != null) {
                  widget.onDragStart();
                }
                if(!_isDragging) {
                  setState(() {
                    _isDragging = true;
                  });
                }
                return [centerWidth, renderBoxBar.size.width];
              } else {
                return null;
              }
            },
            dragUpdate: (position) {
              setState(() {
                final range = widget.max - widget.min;
                _value = range * position + widget.min;
                if(widget.onDragUpdate != null) {
                  widget.onDragUpdate(_value);
                }
              });
            }, dragEnd: () {
            if(_isDragging) {
              setState(() {
                _isDragging = false;
              });
            }
            if(widget.onDragEnd != null) {
              widget.onDragEnd();
            }
          },
          )),
        ],
      ),
    );
  }
}

enum _SliderIds {
  bg,
  fg,
  handler,
  drag
}

class _SCSliderLayoutDelegate extends MultiChildLayoutDelegate {
  final SliderType _type;
  final double _min;
  final double _max;
  final double _value;

  _SCSliderLayoutDelegate(this._type, this._min, this._max, this._value);

  @override
  void performLayout(Size size) {
    Size handlerSize = Size(0, 0);

    if(hasChild(_SliderIds.handler)) {
      final BoxConstraints constraints = BoxConstraints.loose(size);
      handlerSize = layoutChild(_SliderIds.handler, constraints);

      double range = _max - _min;
      double value = _value - _min;
      double offSetX = value / range * (size.width - handlerSize.width);
      positionChild(_SliderIds.handler, Offset(offSetX, (size.height - handlerSize.height) / 2));
    }

    if(hasChild(_SliderIds.bg)) {
      final BoxConstraints constraints = BoxConstraints(
          minWidth: size.width - handlerSize.width,
          maxWidth: size.width - handlerSize.width,
          minHeight: 0,
          maxHeight: double.infinity
      );

      final Size childSize = layoutChild(_SliderIds.bg, constraints);
      positionChild(_SliderIds.bg, Offset(handlerSize.width / 2, (size.height - childSize.height) / 2));
    }

    if(hasChild(_SliderIds.fg)) {
      double range = _max - _min;
      double value = _value - _min;
      double barStartOffset = 0;
      double barWidth = size.width - handlerSize.width;

      switch(_type) {
        case SliderType.NORMAL:
          barWidth = value / range * barWidth;
          barStartOffset = handlerSize.width / 2;
          break;
        case SliderType.CENTER:
          double center = range / 2;
          barStartOffset = (size.width - handlerSize.width) / 2;
          if(value >= center) {
            barWidth = (value - center) / center * barStartOffset;
            barStartOffset += handlerSize.width / 2;
          } else {
            barWidth = (center - value) / center * barStartOffset;
            barStartOffset = barStartOffset + handlerSize.width / 2 - barWidth;
          }
          break;
      }

      final BoxConstraints constraints = BoxConstraints(
          minWidth: barWidth,
          maxWidth: barWidth,
          minHeight: 0,
          maxHeight: size.height
      );

      final Size childSize = layoutChild(_SliderIds.fg, constraints);
      positionChild(_SliderIds.fg, Offset(barStartOffset, (size.height - childSize.height) / 2));
    }

    if(hasChild(_SliderIds.drag)) {
      final BoxConstraints constraints = BoxConstraints.loose(size);
      handlerSize = layoutChild(_SliderIds.drag, constraints);
    }
  }

  @override
  bool shouldRelayout(_SCSliderLayoutDelegate oldDelegate) {
    return oldDelegate._type != _type && oldDelegate._min != _min && oldDelegate._max != _max && oldDelegate._value != _value;
  }
}

class _HorizontalDragWidget extends StatefulWidget {
  final List<double> Function(Offset localPosition) dragStart;
  final Function(double position) dragUpdate;
  final Function() dragEnd;

  const _HorizontalDragWidget({
    Key key,
    @required this.dragStart,
    @required this.dragUpdate,
    @required this.dragEnd}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HorizontalDragState();
}

class _HorizontalDragState extends State<_HorizontalDragWidget> {

  double _isAvailDragCenter;
  double _isAvailDragWidth;
  Offset _tapDownLocalPosition;
  @override
  void initState() {
    _isAvailDragCenter = null;
    _isAvailDragWidth = null;
    _tapDownLocalPosition = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          child: Container(
            color: Colors.white.withOpacity(0.0),
          ),
          onTapDown: (details) {
            _tapDownLocalPosition = details.localPosition;
          },
          onHorizontalDragStart: (DragStartDetails details) {
            final results = widget.dragStart(_tapDownLocalPosition ?? details.localPosition);
            if(results != null && results.length == 2) {
              _isAvailDragCenter = results[0];
              _isAvailDragWidth = results[1];
            } else {
              _isAvailDragCenter = null;
              _isAvailDragWidth = null;
            }
          },
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            if(_isAvailDragCenter != null && _isAvailDragWidth != null) {
              double localPositionDx = details.localPosition.dx + _isAvailDragCenter;
              double maxWidth = constraints.maxWidth - _isAvailDragWidth;
              double dragPosition;
              if(localPositionDx < 0) {
                dragPosition = 0;
              } else if(localPositionDx > maxWidth) {
                dragPosition = 1;
              } else {
                dragPosition = localPositionDx / maxWidth;
              }
              widget.dragUpdate(dragPosition);
            }
          },
          onHorizontalDragEnd: (DragEndDetails details) {
            if(_isAvailDragCenter != null && _isAvailDragWidth != null) {
              widget.dragEnd();
            }
            _isAvailDragCenter = null;
            _isAvailDragWidth = null;
          },
        );
      }
    );
  }
}