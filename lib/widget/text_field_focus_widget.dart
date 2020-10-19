import 'package:flutter/material.dart';

class TextFieldFocusWidget extends StatefulWidget {

  final Widget Function(BuildContext context, FocusNode focusNode) onBuildTextField;
  final void Function(FocusNode focusNode)? onHasFocusNode;

  const TextFieldFocusWidget({Key? key, required this.onBuildTextField, this.onHasFocusNode}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TextFieldFocusState();
}

class _TextFieldFocusState extends State<TextFieldFocusWidget> {

  FocusNode? _focusNode;

  @override
  void initState() {
    _focusNode = FocusNode();
    _focusNode?.addListener(focusNodeListener);
    super.initState();
  }

  @override
  void dispose() {
    if(_focusNode?.hasFocus == true) {
      _focusNode?.unfocus();
    }
    _focusNode?.removeListener(focusNodeListener);
    _focusNode?.dispose();
    _focusNode = null;
    super.dispose();
  }

  void focusNodeListener() {
    var focusNode = _focusNode;
    if (widget.onHasFocusNode != null && focusNode != null) {
      if (focusNode.hasFocus) {
        var onHasFocusNode = widget.onHasFocusNode;
        if (onHasFocusNode != null) {
          onHasFocusNode(focusNode);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var focusNode = _focusNode;
    if(focusNode != null) {
      return widget.onBuildTextField(context, focusNode);
    } else {
      return Container();
    }
  }
}

