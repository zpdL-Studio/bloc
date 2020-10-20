import 'package:flutter/material.dart';
import 'package:zpdl_studio_bloc/bloc/bloc_scaffold.dart';

import 'bloc.dart';

abstract class BLoCChild extends BLoC {

  bool _parentDispose = false;
  bool _attached = false;

  @override
  void dispose() {
    _attached = false;
    if(!_parentDispose) {
      disposeChild();
    }
  }

  void disposeChild();
}

abstract class BLoCChildProvider<T extends BLoCChild> extends BLoCProvider<T> {

  const BLoCChildProvider({Key? key}) : super(key: key);

  @override
  T createBLoC() {
    var bloc = createChildBLoC();
    bloc._attached = true;
    return bloc;
  }

  T createChildBLoC();
}

mixin BLoCParent on BLoC {
  bool _keyboardState = false;
  OnBLoCChildKeyboardStateHasFocusNode? childKeyboardStateHasFocusNode;

  final List<BLoCChild> _blocChildren = [];

  void addChild(BLoCChild child) {
    _blocChildren.add(child);
    child._parentDispose = true;
    if(child is BLoCChildKeyboardState && this is BLoCKeyboardState) {
      child.childKeyboardState = () => _keyboardState;
      child.childKeyboardStateHasFocusNode = hasFocusNodeBLoCKeyboardStateParent;
    }
    if(child is BLoCChildLoading && this is BLoCLoading) {
      child._showBLoCChildLoading = (this as BLoCLoading).showBLoCLoading;
      child._hideBLoCChildLoading = (this as BLoCLoading).hideBLoCLoading;
    }
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
    if(!child._attached) {
      if(child is BLoCChildKeyboardState) {
        child.childKeyboardState = null;
        child.childKeyboardStateHasFocusNode = null;
      }
      if(child is BLoCChildLoading) {
        var _hideBLoCChildLoading = child._hideBLoCChildLoading;
        if(_hideBLoCChildLoading != null) {
          for(var i = 0; i < child._loadingCount; i++) {
            _hideBLoCChildLoading();
          }
        }
        child._showBLoCChildLoading = null;
        child._hideBLoCChildLoading = null;
      }
      child.disposeChild();
    }
  }

  void updateChildKeyboardState(bool show) {
    _keyboardState = show;
    _blocChildren.forEach((element) {
      if(element._attached && element is BLoCChildKeyboardState) {
        element.onBLoCChildKeyboardState(_keyboardState);
      }
    });
  }

  void hasFocusNodeBLoCKeyboardStateParent(FocusNode focusNode) {
    var childKeyboardStateHasFocusNode = this.childKeyboardStateHasFocusNode;
    if(childKeyboardStateHasFocusNode != null) {
      childKeyboardStateHasFocusNode(focusNode);
    }
  }
}

typedef OnBLoCChildKeyboardState = bool Function();
typedef OnBLoCChildKeyboardStateHasFocusNode = void Function(FocusNode focusNode);

mixin BLoCChildKeyboardState on BLoCChild {

  OnBLoCChildKeyboardState? childKeyboardState;
  OnBLoCChildKeyboardStateHasFocusNode? childKeyboardStateHasFocusNode;

  void onBLoCChildKeyboardState(bool show);

  void hasFocusNodeBLoCKeyboardState(FocusNode focusNode) {
    var hasFocusNode = childKeyboardStateHasFocusNode;
    if(hasFocusNode != null) {
      hasFocusNode(focusNode);
    }
  }

  bool getChildKeyboardState() {
    final childKeyboardState = this.childKeyboardState;
    return childKeyboardState != null ? childKeyboardState() : false;
  }
}

mixin BLoCChildLoading on BLoCChild {
  int _loadingCount = 0;

  void Function()? _showBLoCChildLoading;
  void Function()? _hideBLoCChildLoading;

  void showBLoCChildLoading() {
    var _showBLoCChildLoading = this._showBLoCChildLoading;
    if(_showBLoCChildLoading != null) {
      _loadingCount++;
      _showBLoCChildLoading();
    }
  }

  void hideBLoCChildLoading() {
    var _hideBLoCChildLoading = this._hideBLoCChildLoading;
    if(_hideBLoCChildLoading != null) {
      _loadingCount--;
      _hideBLoCChildLoading();
    }
  }
}