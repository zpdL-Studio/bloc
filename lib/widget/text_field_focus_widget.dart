import 'package:flutter/material.dart';

class TextFieldFocusWidget extends StatefulWidget {

  final Widget Function(BuildContext context, FocusNode focusNode) onBuildTextField;
  final void Function(FocusNode focusNode) onHasFocusNode;

  const TextFieldFocusWidget({Key key, @required this.onBuildTextField, this.onHasFocusNode}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TextFieldFocusState();
}

class _TextFieldFocusState extends State<TextFieldFocusWidget> {

  FocusNode _focusNode;

  @override
  void initState() {
    _focusNode = FocusNode();
    _focusNode.addListener(this.focusNodeListener);
    super.initState();
  }

  @override
  void dispose() {
    if(_focusNode?.hasFocus == true) {
      _focusNode?.unfocus();
    }
    _focusNode?.removeListener(this.focusNodeListener);
    _focusNode?.dispose();
    _focusNode = null;
    super.dispose();
  }

  void focusNodeListener() {
    if(widget.onHasFocusNode != null && _focusNode != null) {
      if(_focusNode.hasFocus) {
        widget.onHasFocusNode(_focusNode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.onBuildTextField(context, _focusNode);
  }
}

