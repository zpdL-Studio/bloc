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

abstract class BLoCChild extends BLoC {

  bool _parentDispose = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    if(!_parentDispose) {
      disposeChild();
    }
  }

  void disposeChild();
}

abstract class BLoCProvider<T extends BLoC> extends StatefulWidget {

  const BLoCProvider({Key key}) : super(key: key);

  static T of<T extends BLoC>(BuildContext context) {
    final BLoCProviderState<T> state = context.findAncestorStateOfType<BLoCProviderState<T>>();
    return state?.bloc;
  }

  @override
  State<StatefulWidget> createState() => BLoCProviderState<T>();

  T createBLoC();

  Widget build(BuildContext context, T bloc);
}

class BLoCProviderState<T extends BLoC> extends State<BLoCProvider> with WidgetsBindingObserver {

  @protected T bloc;
  @protected BLoCLifeCycle lifeCycle;
  @protected BLoCKeyboardState keyboardState;
  @protected BLoCLoading loading;
  @protected BLoCParent parent;

  @override
  void initState() {
    bloc = widget.createBLoC();
    bloc?._setOnMounted(() => this.mounted);
    bloc?._setOnBuildContext(() => this.context);
    bloc?._setOnSetState((fn) => setState(fn));

    if(bloc is BLoCLifeCycle) {
      lifeCycle = bloc as BLoCLifeCycle;
      WidgetsBinding.instance.addObserver(this);
    }
    if(bloc is BLoCKeyboardState) {
      keyboardState = bloc as BLoCKeyboardState;
    }
    if(bloc is BLoCLoading) {
      loading = bloc as BLoCLoading;
    }
    if(bloc is BLoCParent) {
      parent = bloc as BLoCParent;
    }

    super.initState();
  }

  @override
  void dispose() {
    if(lifeCycle != null) {
      WidgetsBinding.instance.removeObserver(this);
      lifeCycle._pause();
      lifeCycle = null;
     }
    keyboardState = null;
    loading?.disposeBLoCLoading();
    loading = null;
    parent?.disposeParent();
    parent = null;

    bloc?._setOnSetState(null);
    bloc?._setOnBuildContext(null);
    bloc?.dispose();
    bloc = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(bloc != null) {
      lifeCycle?._updateLifeCycle(context);
      keyboardState?._updateKeyboardState(context);
      if(loading != null) {
        return Stack(
          children: [
            Builder(
              builder: (context) {
                return widget.build(context, bloc);
              },
            ),
            StreamBuilderToWidget(
                stream: loading.getBLoCLoadingStatusStream, 
                builder: loading.buildBLoCLoading)
          ],
        );
      } else {
        return Builder(
          builder: (context) {
            return widget.build(context, bloc);
          },
        );
      }
    }
    return Container();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    lifeCycle?._didChangeAppLifecycleState(state);
  }
}

mixin BLoCLifeCycle on BLoC {
  bool _resumed = false;

  void _updateLifeCycle(BuildContext context) {
    bool isCurrent = _getIsCurrent(context);
    if(isCurrent) {
      _resume();
    } else {
      _pause();
    }
  }

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
        if(onShowLoading != null) onShowLoading();
      }).listen(
          onData,
          onError: ([error, stackTrace]) {
            if(onHideLoading != null) onHideLoading();

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
            if(onHideLoading != null) onHideLoading();

            if(onDone != null) {
              onDone(true);
            }
          },
          cancelOnError: true
      ),
    );
  }
}

mixin BLoCParent on BLoC {

  List<BLoCChild> _blocChildren = List();

  void addChild(BLoCChild child) {
    _blocChildren.add(child);
    child._parentDispose = true;
  }

  void removeChild(BLoCChild child) {
    if(_blocChildren.remove(child)) {
      _disposeChild(child);
    }
  }

  void disposeParent() {
    _blocChildren.removeWhere((element) {
      _disposeChild(element);
      return true;
    });
  }

  void _disposeChild(BLoCChild child) {
    child._parentDispose = false;
    if(child._disposed) {
      child.disposeChild();
    }
  }
}

