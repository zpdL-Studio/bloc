import 'package:flutter/material.dart';

import 'bloc.dart';

abstract class BLoCScaffold extends BLoC {

}

abstract class BLoCScaffoldProvider<T extends BLoCScaffold> extends BLoCProvider<T> {
  final Color backgroundColor;
  final Color bodyColor;
  final bool resizeToAvoidBottomInset;

  const BLoCScaffoldProvider({this.backgroundColor, this.bodyColor, this.resizeToAvoidBottomInset, Key key}) : super(key: key);

  PreferredSizeWidget appBar(BuildContext context, T bloc);

  Widget body(BuildContext context, T bloc);

  @override
  Widget build(BuildContext context, T bloc) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar(context, bloc),
      body: bodyColor != null
          ? Container(
              color: bodyColor,
              child: body(context, bloc),
            )
          : body(context, bloc),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}