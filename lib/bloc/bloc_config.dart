import 'package:flutter/material.dart';
import 'bloc.dart';

class BLoCConfig {
  static final BLoCConfig _instance = BLoCConfig._();

  factory BLoCConfig() => _instance;

  BLoCConfig._();

  int loadingDelayMs = 300;
  int loadingHideDelayMs = 30;

  String unknownExceptionMessage = "Unknown";

  Widget Function(BuildContext context, BLoCLoadingStatus status) loadingBuilder =
      (BuildContext context, BLoCLoadingStatus status) {
    switch(status) {
      case BLoCLoadingStatus.INIT:
        return Container();
      case BLoCLoadingStatus.LOCK:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
        );
      case BLoCLoadingStatus.LOADING:
      case BLoCLoadingStatus.HIDING:
      return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          alignment: AlignmentDirectional.center,
          child: Container(
              width: 40, height: 40, child: CircularProgressIndicator()));
    }
    return Container();
  };

  void Function(BuildContext context, Exception e) streamSubscriptionError =
      (BuildContext context, Exception e) {
        showDialog(
          context: context,
          child: AlertDialog(
            contentPadding: EdgeInsets.all(16),
            content: Text(e.toString()),
            actions: <Widget>[
              FlatButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.pop(context, "OK");
                },
              ),
            ],
          )
        );
      };
}

