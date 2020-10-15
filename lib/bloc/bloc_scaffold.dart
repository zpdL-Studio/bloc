import 'dart:async';

import 'package:flutter/material.dart';

import 'bloc.dart';

abstract class BLoCScaffold extends BLoC with BLoCLoading, BLoCStreamSubscription {

  void onStreamSubscriptionShowLoading() {
    showBLoCLoading();
  }

  void onStreamSubscriptionHideLoading() {
    hideBLoCLoading();
  }

  StreamSubscription<T> scaffoldSubscription<T>({
    @required Stream<T> stream,
    @required void Function(T data) onData,
    void Function(bool success) onDone,
    bool Function(Exception exception) onError
  }) {
    return streamSubscription<T>(
      stream: stream,
      onData: onData,
      onDone: onDone,
      onError: onError,
      onShowLoading: onStreamSubscriptionShowLoading,
      onHideLoading: onStreamSubscriptionHideLoading
    );
  }
}

abstract class BLoCScaffoldProvider<T extends BLoC> extends BLoCProvider<T> {
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