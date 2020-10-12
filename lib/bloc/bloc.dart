import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';
import 'package:zpdl_studio_bloc/widget/stream_builder_to_widget.dart';

import 'bloc_config.dart';

abstract class BLoC {

  BuildContext Function() _onBuildContext;
  bool Function() _onMounted;

  BuildContext get buildContext {
    if(_onBuildContext != null) {
      return _onBuildContext();
    }
    return null;
  }

  void _setOnBuildContext(BuildContext Function() onBuildContext) {
    _onBuildContext = onBuildContext;
  }

  void _setOnMounted(bool Function() onMounted) {
    _onMounted = onMounted;
  }

  void Function(VoidCallback) _onSetState;
  void _setOnSetState(void Function(VoidCallback) onSetState) {
    _onSetState = onSetState;
  }

  void setState(VoidCallback fn) {
    if(_onMounted != null && _onMounted() && _onSetState != null) {
      _onSetState(fn);
    }
  }

  void dispose();
}

abstract class BLoCProvider<T extends BLoC> extends StatefulWidget {

  const BLoCProvider({Key key}) : super(key: key);

  static T of<T extends BLoC>(BuildContext context) {
    final _BLoCProviderState<T> state = context.findAncestorStateOfType<_BLoCProviderState<T>>();
    return state?._bloc;
  }

  @override
  State<StatefulWidget> createState() => _BLoCProviderState<T>();

  T createBLoC();

  Widget build(BuildContext context, T bloc);
}

class _BLoCProviderState<T extends BLoC> extends State<BLoCProvider> with WidgetsBindingObserver {

  T _bloc;
  BLoCLifeCycle _lifeCycle;
  BLoCKeyboardState _keyboardState;
  BLoCLoading _loading;

  @override
  void initState() {
    _bloc = widget.createBLoC();
    _bloc?._setOnMounted(() => this.mounted);
    _bloc?._setOnBuildContext(() => this.context);
    _bloc?._setOnSetState((fn) => setState(fn));

    if(_bloc is BLoCLifeCycle) {
      _lifeCycle = _bloc as BLoCLifeCycle;
      WidgetsBinding.instance.addObserver(this);
    }
    if(_bloc is BLoCKeyboardState) {
      _keyboardState = _bloc as BLoCKeyboardState;
    }
    if(_bloc is BLoCLoading) {
      _loading = _bloc as BLoCLoading;
    }

    super.initState();
  }

  @override
  void dispose() {
    if(_lifeCycle != null) {
      WidgetsBinding.instance.removeObserver(this);
      _lifeCycle = null;
     }
    _keyboardState = null;
    _loading?.disposeBLoCLoading();
    _loading = null;

    _bloc?._setOnSetState(null);
    _bloc?._setOnBuildContext(null);
    _bloc?.dispose();
    _bloc = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(_bloc != null) {
      _lifeCycle?._updateLifeCycle(context);
      _keyboardState?._updateKeyboardState(context);
      if(_loading != null) {
        return Stack(
          children: [
            widget.build(context, _bloc),
            StreamBuilderToWidget(
                stream: _loading.getBLoCLoadingStatusStream, 
                builder: _loading.buildBLoCLoading)
          ],
        );
      } else {
        return widget.build(context, _bloc);
      }
    }
    return Container();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lifeCycle?._didChangeAppLifecycleState(state);
  }
}

mixin BLoCLifeCycle on BLoC {
  bool _isCurrent;
  bool _resumed = false;

  void _updateLifeCycle(BuildContext context) {
    bool isCurrent = _getIsCurrent(context);
    if(_isCurrent != isCurrent) {
      _isCurrent = isCurrent;
      if(_isCurrent) {
        _resume(context);
      } else {
        _pause(context);
      }
    }
  }

  void _didChangeAppLifecycleState(AppLifecycleState state) {
    BuildContext context = buildContext;
    if(context != null) {
      _isCurrent = _getIsCurrent(context);
      if(_isCurrent) {
        if (state == AppLifecycleState.resumed) {
          _resume(context);
        } else if (state == AppLifecycleState.paused) {
          _pause(context);
        }
      }
    }
  }

  bool _getIsCurrent(BuildContext context) {
    return ModalRoute.of(context)?.isCurrent ?? false;
  }

  void _resume(BuildContext context) async {
    if(!_resumed) {
      _resumed = true;
      onLifeCycleResume(context);
    }
  }

  void _pause(BuildContext context) async {
    if(_resumed) {
      _resumed = false;
      onLifeCyclePause(context);
    }
  }

  void onLifeCycleResume(BuildContext context);

  void onLifeCyclePause(BuildContext context);
}

mixin BLoCKeyboardState on BLoC {

  bool _isShowingKeyboard = false;

  bool get isShowingKeyboard => _isShowingKeyboard;

  void _updateKeyboardState(BuildContext context) {
    bool showingKeyboard = (MediaQuery.of(context)?.viewInsets?.bottom ?? 0) > 0;
    if(_isShowingKeyboard != showingKeyboard) {
      _isShowingKeyboard = showingKeyboard;
      onKeyboardState(_isShowingKeyboard);
    }
  }

  void onKeyboardState(bool show);
}


enum BLoCLoadingStatus {
  INIT,
  LOCK,
  LOADING,
  HIDING
}

mixin BLoCLoading on BLoC {
  int _count = 0;

  final _blocLoadingStatus = BehaviorSubject<BLoCLoadingStatus>()..add(BLoCLoadingStatus.INIT);
  Stream<BLoCLoadingStatus> get getBLoCLoadingStatusStream => _blocLoadingStatus.stream;

  void disposeBLoCLoading() {
    _blocLoadingStatus.close();
  }

  void showBLoCLoading() async {
    switch(await _blocLoadingStatus.first) {
      case BLoCLoadingStatus.INIT:
        _count = 1;
        if(BLoCConfig().loadingDelayMs > 0) {
          _blocLoadingStatus.sink.add(BLoCLoadingStatus.LOCK);
          Future.delayed(Duration(milliseconds: BLoCConfig().loadingDelayMs)).then((data) async {
            if (await _blocLoadingStatus.first == BLoCLoadingStatus.LOCK) {
              _blocLoadingStatus.sink.add(BLoCLoadingStatus.LOADING);
            }
          });
        } else {
          _blocLoadingStatus.sink.add(BLoCLoadingStatus.LOADING);
        }
        break;
      case BLoCLoadingStatus.LOCK:
        _count++;
        break;
      case BLoCLoadingStatus.LOADING:
        _count++;
        break;
      case BLoCLoadingStatus.HIDING:
        _count++;
        if(_count > 0) {
          _blocLoadingStatus.sink.add(BLoCLoadingStatus.LOADING);
        }
        break;
    }
  }

  void hideBLoCLoading() async {
    switch(await _blocLoadingStatus.first) {
      case BLoCLoadingStatus.INIT:
        _count = 0;
        break;
      case BLoCLoadingStatus.LOCK:
        _count--;
        if(_count <= 0) {
          _count = 0;
          _blocLoadingStatus.sink.add(BLoCLoadingStatus.INIT);
        }
        break;
      case BLoCLoadingStatus.LOADING:
        _count--;
        if(_count <= 0) {
          _count = 0;
          if(BLoCConfig().loadingHideDelayMs > 0) {
            _blocLoadingStatus.sink.add(BLoCLoadingStatus.HIDING);
            _hide(BLoCConfig().loadingHideDelayMs);
          } else {
            _blocLoadingStatus.sink.add(BLoCLoadingStatus.INIT);
          }
        }
        break;
      case BLoCLoadingStatus.HIDING:
        _count--;
        break;
    }
  }

  void _hide(int delayMs) {
    Future.delayed(Duration(milliseconds: delayMs)).then((data) {
      if (_count <= 0) {
        _blocLoadingStatus.sink.add(BLoCLoadingStatus.INIT);
      }
    });
  }
  
  Widget buildBLoCLoading(BuildContext context, BLoCLoadingStatus status) => BLoCConfig().loadingBuilder(context, status);
}

mixin BLoCStreamSubscription on BLoC {
  final _compositeSubscription = CompositeSubscription();

  void onStreamSubscriptionError(Exception e) {
    BuildContext context = buildContext;
    if(context != null) {
      BLoCConfig().streamSubscriptionError(context, e);
    }
  }

  void onStreamSubscriptionShowLoading() {
    if(this is BLoCLoading) {
      (this as BLoCLoading).showBLoCLoading();
    }
  }

  void onStreamSubscriptionHideLoading() {
    if(this is BLoCLoading) {
      (this as BLoCLoading).hideBLoCLoading();
    }
  }

  StreamSubscription<T> streamSubscription<T>({
    @required Stream<T> stream,
    @required void Function(T data) onData,
    void Function(bool success) onDone,
    bool Function(Exception exception) onError,
    void Function() onShowLoading,
    void Function() onHideLoading,
  }) {
    return _compositeSubscription.add(
      DeferStream(() => stream,
      ).doOnListen(() {
        onShowLoading != null ? onShowLoading() : onStreamSubscriptionShowLoading();
      }).listen(
          onData,
          onError: ([error, stackTrace]) {
            onHideLoading != null ? onHideLoading() : onStreamSubscriptionHideLoading();

            if(!(error is Exception)) {
              return;
            }
            var errorResult = onError != null ? onError(error) : false;
            if(!errorResult) {
              onStreamSubscriptionError(error);
            }
            if(onDone != null) {
              onDone(false);
            }
          },
          onDone: () {
            onHideLoading != null ? onHideLoading() : onStreamSubscriptionHideLoading();

            if(onDone != null) {
              onDone(true);
            }
          },
          cancelOnError: true
      ),
    );
  }
}

