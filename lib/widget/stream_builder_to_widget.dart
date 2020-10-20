import 'package:flutter/material.dart';


class StreamBuilderToWidget<T> extends StatelessWidget {

  const StreamBuilderToWidget({Key key, this.initialData, this.stream, @required this.builder, this.noHasDataWidget}) : super(key: key);

  final T initialData;
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget noHasDataWidget;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      initialData: initialData,
      stream: stream,
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

class StreamBuilderToSliver<T> extends SliverToBoxAdapter {
  StreamBuilderToSliver(
      {Key key,
      T initialData,
      Stream<T> stream,
      @required Widget Function(BuildContext context, T data) builder,
      Widget noHasDataWidget})
      : super(
            key: key,
            child: StreamBuilderToWidget(
              initialData: initialData,
              stream: stream,
              builder: builder,
              noHasDataWidget: noHasDataWidget,
            ));
}

class StreamBuilderToSliverList<T> extends StatelessWidget {

  const StreamBuilderToSliverList({Key key, this.stream, @required this.builder, this.emptyWidget}) : super(key: key);

  final Stream<List<T>> stream;
  final Widget Function(BuildContext context, T data, int index, int size) builder;
  final Widget emptyWidget;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) {
        if(snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return builder(context, snapshot.data[index], index, snapshot.data.length);
            }, childCount: snapshot.data.length
            ));
          } else {
            return emptyWidget != null
                ? SliverList(delegate: SliverChildBuilderDelegate((context, index) {
              return emptyWidget;
            }, childCount: 1))
                : emptySliverList();
          }
        } else {
          return emptySliverList();
        }
      },
    );
  }

  static SliverList emptySliverList() =>
      SliverList(delegate: SliverChildBuilderDelegate((context, index) {
        return Container();
      }, childCount: 0));
}