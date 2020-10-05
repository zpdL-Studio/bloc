import 'package:flutter/material.dart';

abstract class BLoC {

  BuildContext Function() _onBuildContext;

  BuildContext get buildContext {
    if(_onBuildContext != null) {
      return _onBuildContext();
    }
    return null;
  }

  void _setOnBuildContext(BuildContext Function() onBuildContext) {
    _onBuildContext = onBuildContext;
  }

  void Function(VoidCallback) _onSetState;
  void _setOnSetState(void Function(VoidCallback) onSetState) {
    _onSetState = onSetState;
  }

  void setState(VoidCallback fn) {
    if(_onSetState != null) {
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

  @override
  void initState() {
    _bloc = widget.createBLoC();
    _bloc?._setOnBuildContext(() => this.context);
    _bloc?._setOnSetState((fn) => setState(fn));

    if(_bloc is BLoCLifeCycle) {
      _lifeCycle = _bloc as BLoCLifeCycle;
      WidgetsBinding.instance.addObserver(this);
    }
    if(_bloc is BLoCKeyboardState) {
      _keyboardState = _bloc as BLoCKeyboardState;
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

      return widget.build(context, _bloc);
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
        _resume();
      } else {
        _pause();
      }
    }
  }

  void _didChangeAppLifecycleState(AppLifecycleState state) {
    BuildContext context = buildContext;
    if(context != null) {
      _isCurrent = _getIsCurrent(context);
      if(_isCurrent) {
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

