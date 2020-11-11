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

  @override
  @mustCallSuper
  void dispose() {
    if (this is BLoCParent) {
      (this as BLoCParent).disposeParent();
    }
  }
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

class _BLoCScaffoldLifeCycleObserver {
  static final _BLoCScaffoldLifeCycleObserver _instance = _BLoCScaffoldLifeCycleObserver._();

  _BLoCScaffoldLifeCycleObserver._();

  factory _BLoCScaffoldLifeCycleObserver() => _instance;

  List<BLoCScaffold> list = [];

  void subscribe(BLoCScaffold bloc) {
    for(final _bloc in list) {
      if(_bloc is BLoCLifeCycle) {
        _bloc._pause();
      }
    }

    if(bloc is BLoCLifeCycle) {
      bloc._resume();
    }
    list.add(bloc);
  }

  void unsubscribe(BLoCScaffold bloc) {
    if(bloc is BLoCLifeCycle) {
      bloc._pause();
    }
    list.remove(bloc);
    if(list.isNotEmpty) {
      final _bloc = list.last;
      if(_bloc is BLoCLifeCycle) {
        _bloc._resume();
      }
    }
  }
}

class BLoCScaffoldProviderState<T extends BLoCScaffold> extends BLoCProviderState<T> with WidgetsBindingObserver {
  @protected BLoCKeyboardState keyboardState;
  @protected BLoCLifeCycle lifeCycle;

  @override
  void initBLoC(T bloc) {
    if(bloc is BLoCKeyboardState) {
      keyboardState = bloc;
      if(keyboardState is BLoCParent) {
        keyboardState.addBLoCKeyboardStateListener((bloc as BLoCParent).updateChildKeyboardState);
        (keyboardState as BLoCParent).childKeyboardStateHasFocusNode = keyboardState.hasFocusNodeBLoCKeyboardState;
      }
    }
    if(bloc is BLoCLifeCycle) {
      lifeCycle = bloc;
      WidgetsBinding.instance.addObserver(this);
    }
    super.initBLoC(bloc);
  }

  @override
  void disposeBLoC(T bloc) {
    if(keyboardState != null) {
      if(keyboardState is BLoCParent) {
        keyboardState.removeBLoCKeyboardStateListener((bloc as BLoCParent).updateChildKeyboardState);
        (keyboardState as BLoCParent).childKeyboardStateHasFocusNode = null;
      }
    }
    keyboardState = null;
    if(lifeCycle != null) {
      lifeCycle = null;
      WidgetsBinding.instance.removeObserver(this);
    }
    _BLoCScaffoldLifeCycleObserver().unsubscribe(bloc);
    super.disposeBLoC(bloc);
  }

  @override
  Widget buildBLoC(BuildContext context, T bloc, Widget widget) {
    keyboardState?._updateKeyboardState(context);
    return super.buildBLoC(context, bloc, widget);
  }

  @override
  void didChangeDependencies() {
    final bloc = this.bloc;
    if(bloc != null) {
      _BLoCScaffoldLifeCycleObserver().subscribe(bloc);
    }
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    lifeCycle?._didChangeAppLifecycleState(state);
    super.didChangeAppLifecycleState(state);
  }
}

typedef BLoCKeyboardStateListener = void Function(bool);

typedef BLoCKeyboardStateHasFocusNode = void Function(FocusNode focusNode);

mixin BLoCKeyboardState on BLoCScaffold {

  bool _isShowingKeyboard = false;

  bool get isShowingKeyboard => _isShowingKeyboard;

  void _updateKeyboardState(BuildContext context) {
    bool showingKeyboard = (MediaQuery.of(context)?.viewInsets?.bottom ?? 0) > 0;
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

  List<void Function(bool)> _listener = List();

  void addBLoCKeyboardStateListener(BLoCKeyboardStateListener listener) {
    if(listener != null) {
      _listener.add(listener);
    }
  }

  void removeBLoCKeyboardStateListener(BLoCKeyboardStateListener listener) {
    if(listener != null) {
      _listener.remove(listener);
    }
  }

  FocusNode _focusNode;
  void hasFocusNodeBLoCKeyboardState(FocusNode focusNode) {
    _focusNode = focusNode;
  }
}

mixin BLoCLifeCycle on BLoCScaffold {
  bool _resumed = false;

  bool get lifeCycleResumed => _resumed;

  void _didChangeAppLifecycleState(AppLifecycleState state) {
    BuildContext context = buildContext;
    if(context != null) {
      if(_getIsCurrent(context)) {
        if (state == AppLifecycleState.resumed) {
          _resume();
        } else if (state == AppLifecycleState.paused) {
          _pause();
        }
      }
    }
  }

  bool _getIsCurrent(BuildContext context) {
    return ModalRoute.of(context)?.isCurrent ?? false;
  }

  void _resume() async {
    if(!_resumed) {
      _resumed = true;
      onLifeCycleResume();
    }
  }

  void _pause() async {
    if(_resumed) {
      _resumed = false;
      onLifeCyclePause();
    }
  }

  void onLifeCycleResume();

  void onLifeCyclePause();

}