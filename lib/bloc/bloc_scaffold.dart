import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zpdl_studio_bloc/bloc/bloc_child.dart';
import 'package:zpdl_studio_bloc/widget/ios_out_side_unfocus_tap.dart';

import 'bloc.dart';

abstract class BLoCScaffold extends BLoC with BLoCLoading, BLoCStreamSubscription {

  void onStreamSubscriptionShowLoading() {
    showBLoCLoading();
  }

  void onStreamSubscriptionHideLoading() {
    hideBLoCLoading();
  }

  StreamSubscription<T> scaffoldSubscription<T>({
    required Stream<T> stream,
    required void Function(T data) onData,
    void Function(bool success)? onDone,
    bool Function(Exception exception)? onError
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

abstract class BLoCScaffoldProvider<T extends BLoCScaffold> extends BLoCProvider<T> {
  final Color? backgroundColor;
  final Color? bodyColor;
  final bool resizeToAvoidBottomInset;

  const BLoCScaffoldProvider({this.backgroundColor, this.bodyColor, this.resizeToAvoidBottomInset = false, Key? key}) : super(key: key);

  PreferredSizeWidget appBar(BuildContext context, T bloc);

  Widget body(BuildContext context, T bloc);

  @override
  Widget build(BuildContext context, T bloc) {
    return IosOutSideUnFocusTab(
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar(context, bloc),
        body: bodyColor != null
            ? Container(
          color: bodyColor,
          child: body(context, bloc),
        )
            : body(context, bloc),
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => BLoCScaffoldProviderState<T>();
}

class BLoCScaffoldProviderState<T extends BLoCScaffold> extends BLoCProviderState<T> {
  @protected BLoCKeyboardState? keyboardState;

  @override
  void initBLoC(T bloc) {
    if(bloc is BLoCKeyboardState) {
      keyboardState = bloc;
      if(keyboardState is BLoCParent) {
        keyboardState?.addBLoCKeyboardStateListener((bloc as BLoCParent).updateChildKeyboardState);
        (keyboardState as BLoCParent).childKeyboardStateHasFocusNode = keyboardState?.hasFocusNodeBLoCKeyboardState;
      }
    }
    super.initBLoC(bloc);
  }

  @override
  void disposeBLoC(T bloc) {
    if(keyboardState != null) {
      if(keyboardState is BLoCParent) {
        keyboardState?.removeBLoCKeyboardStateListener((bloc as BLoCParent).updateChildKeyboardState);
        (keyboardState as BLoCParent).childKeyboardStateHasFocusNode = null;
      }
    }
    keyboardState = null;
    super.disposeBLoC(bloc);
  }

  @override
  Widget buildBLoC(BuildContext context, T bloc, Widget widget) {
    keyboardState?._updateKeyboardState(context);
    return super.buildBLoC(context, bloc, widget);
  }
}

typedef BLoCKeyboardStateListener = void Function(bool);

typedef BLoCKeyboardStateHasFocusNode = void Function(FocusNode focusNode);

mixin BLoCKeyboardState on BLoCScaffold {

  bool _isShowingKeyboard = false;

  bool get isShowingKeyboard => _isShowingKeyboard;

  void _updateKeyboardState(BuildContext context) {
    var showingKeyboard = (MediaQuery.of(context)?.viewInsets.bottom ?? 0) > 0;
    if(_isShowingKeyboard != showingKeyboard) {
      _isShowingKeyboard = showingKeyboard;
      onKeyboardState(_isShowingKeyboard);
    }
  }

  @mustCallSuper
  void onKeyboardState(bool show) {
    if(!show && _focusNode?.hasFocus == true) {
      _focusNode?.unfocus();
    }

    for(final listener in _listener) {
      listener(show);
    }
  }

  final List<void Function(bool)> _listener = [];

  void addBLoCKeyboardStateListener(BLoCKeyboardStateListener listener) {
    _listener.add(listener);
  }

  void removeBLoCKeyboardStateListener(BLoCKeyboardStateListener listener) {
    _listener.remove(listener);
  }

  FocusNode? _focusNode;
  void hasFocusNodeBLoCKeyboardState(FocusNode? focusNode) {
    _focusNode = focusNode;
  }
}