import 'package:flutter/material.dart';


class FutureBuilderToWidget<T> extends StatelessWidget {

  const FutureBuilderToWidget({Key key, this.initialData, this.future, @required this.builder, this.noHasDataWidget}) : super(key: key);

  final T initialData;
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget noHasDataWidget;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      initialData: initialData,
      future: future,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        if(snapshot.hasData) {
          return builder(context, snapshot.data);
        } else {
          return noHasDataWidget != null ? noHasDataWidget : Container();
        }
      },
    );
  }
}

class FutureBuilderToSliver<T> extends SliverToBoxAdapter {
  FutureBuilderToSliver(
      {Key key,
      T initialData,
      Future<T> future,
      @required Widget Function(BuildContext context, T data) builder,
      Widget noHasDataWidget})
      : super(
            key: key,
            child: FutureBuilderToWidget(
              initialData: initialData,
              future: future,
              builder: builder,
              noHasDataWidget: noHasDataWidget,
            ));
}