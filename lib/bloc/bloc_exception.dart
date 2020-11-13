import 'bloc_config.dart';

abstract class BLoCException implements Exception {
  final String message;

  BLoCException(this.message);

  @override
  String toString() {
    return message;
  }
}

class BLoCUnknownException extends BLoCException {

  BLoCUnknownException() : super(BLoCConfig().unknownExceptionMessage);
}