import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'bloc_child.dart';
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
    if(bloc is BLoCLoading) {
      loading = bloc as BLoCLoading;
    }
    if(bloc is BLoCParent) {
      parent = bloc as BLoCParent;
    }
    if(bloc != null) {
      initBLoC(bloc);
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
    loading = null;
    parent?.disposeParent();
    parent = null;

    if(bloc != null) {
      disposeBLoC(bloc);
      bloc._setOnSetState(null);
      bloc._setOnBuildContext(null);
      bloc.dispose();
      bloc = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(bloc != null) {
      lifeCycle?._updateLifeCycle(context);
      if(loading != null) {
        return Stack(
          children: [
            Builder(
              builder: (context) {
                return buildBLoC(context, bloc, widget.build(context, bloc));
              },
            ),
            BLoCLoadingWidget(
                notify: (notify) {
                  loading._notify = notify;
                  return loading._status;
                },
                builder: loading.buildBLoCLoading
            )
          ],
        );
      } else {
        return Builder(
          builder: (context) {
            return buildBLoC(context, bloc, widget.build(context, bloc));
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

  void initBLoC(T bloc) {}

  void disposeBLoC(T bloc) {}

  Widget buildBLoC(BuildContext context, T bloc, Widget widget) => widget;
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

enum BLoCLoadingStatus {
  INIT,
  LOCK,
  LOADING,
  HIDING
}

typedef BLoCLoadingWidgetNotify = void Function(BLoCLoadingStatus status);

mixin BLoCLoading on BLoC {
  int _count = 0;
  BLoCLoadingStatus _status = BLoCLoadingStatus.INIT;

  BLoCLoadingWidgetNotify _notify;

  void _setStatus(BLoCLoadingStatus status) {
    _status = status;
    if(_notify != null) {
      _notify(_status);
    }
  }

  void showBLoCLoading() {
    switch(_status) {
      case BLoCLoadingStatus.INIT:
        _count = 1;
        if(BLoCConfig().loadingDelayMs > 0) {
          _setStatus(BLoCLoadingStatus.LOCK);
          Future.delayed(Duration(milliseconds: BLoCConfig().loadingDelayMs)).then((data) async {
            if (_status == BLoCLoadingStatus.LOCK) {
              _setStatus(BLoCLoadingStatus.LOADING);
            }
          });
        } else {
          _setStatus(BLoCLoadingStatus.LOADING);
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
          _setStatus(BLoCLoadingStatus.LOADING);
        }
        break;
    }
  }

  void hideBLoCLoading() {
    switch(_status) {
      case BLoCLoadingStatus.INIT:
        _count = 0;
        break;
      case BLoCLoadingStatus.LOCK:
        _count--;
        if(_count <= 0) {
          _count = 0;
          _setStatus(BLoCLoadingStatus.INIT);
        }
        break;
      case BLoCLoadingStatus.LOADING:
        _count--;
        if(_count <= 0) {
          _count = 0;
          if(BLoCConfig().loadingHideDelayMs > 0) {
            _setStatus(BLoCLoadingStatus.HIDING);
            _hide(BLoCConfig().loadingHideDelayMs);
          } else {
            _setStatus(BLoCLoadingStatus.INIT);
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
        _setStatus(BLoCLoadingStatus.INIT);
      }
    });
  }
  
  Widget buildBLoCLoading(BuildContext context, BLoCLoadingStatus status) => BLoCConfig().loadingBuilder(context, status);
}

class BLoCLoadingWidget extends StatefulWidget {

  final Widget Function(BuildContext context, BLoCLoadingStatus status) builder;
  final BLoCLoadingStatus Function(BLoCLoadingWidgetNotify notify) notify;

  const BLoCLoadingWidget({Key key, @required this.builder, @required this.notify}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BLoCLoadingState();
}

class _BLoCLoadingState extends State<BLoCLoadingWidget> {
  BLoCLoadingStatus _status;

  @override
  void initState() {
    _status = widget.notify((BLoCLoadingStatus status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.notify(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _status);
  }
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