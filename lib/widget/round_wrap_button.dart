import 'package:flutter/material.dart';
import 'package:zpdl_studio_bloc/widget/touch_well.dart';

import 'wrap_content_widget.dart';

class RoundWrapButton extends StatelessWidget {

  const RoundWrapButton({
    Key? key,
    required this.child,
    double? minWidth,
    double? maxWidth,
    double? width,
    double? minHeight,
    double? maxHeight,
    double? height,
    this.padding = const EdgeInsets.all(0),
    double? radius,
    Color? colorBgEnable,
    Color? colorBgDisable,
    Color? colorBg,
    Color? colorBorderEnable,
    Color? colorBorderDisable,
    Color? colorBorder,
    this.onTap})
      : radius = radius ?? ((minHeight ?? height ?? 0) / 2),
        minWidth = (minWidth ?? width),
        maxWidth = (maxWidth ?? width),
        minHeight = (minHeight ?? height),
        maxHeight = (maxHeight ?? height),
        colorBgEnable = colorBgEnable ?? colorBg,
        colorBgDisable = colorBgDisable ?? colorBg,
        colorBorderEnable = colorBorderEnable ?? colorBorder,
        colorBorderDisable = colorBorderDisable ?? colorBorder,
        super(key: key);

  final Widget child;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;
  final double radius;

  final Color? colorBgEnable;
  final Color? colorBgDisable;
  final Color? colorBorderEnable;
  final Color? colorBorderDisable;

  final GestureTapCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: _buildBoxDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: TouchWell(
            onTap: onTap,
            child: Container(
                constraints: BoxConstraints(
                  minWidth: minWidth ??  0,
                  maxWidth: maxWidth ??  double.infinity,
                  minHeight: minHeight ?? 0,
                  maxHeight: maxHeight ?? double.infinity,
                ),
                padding: padding,
                child: WrapContent(
                    minWidth: minWidth ??  0,
                    maxWidth: maxWidth ??  double.infinity,
                    minHeight: minHeight ?? 0,
                    maxHeight: maxHeight ?? double.infinity,
                    child: child
                )
            ),
          ),
        )
    );
  }

  BoxDecoration _buildBoxDecoration() {
    if(onTap != null) {
      return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
              color: colorBorderEnable ?? Colors.transparent,
              width: 1,
              style: BorderStyle.solid
          ),
          color: colorBgEnable ?? Colors.transparent,
      );
    } else {
      return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
              color: colorBorderDisable ?? Colors.transparent,
              width: 1,
              style: BorderStyle.solid
          ),
          color: colorBgDisable ?? Colors.transparent,
      );
    }
  }
}