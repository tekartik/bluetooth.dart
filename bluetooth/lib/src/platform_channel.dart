import 'package:rxdart/rxdart.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

/// An command object representing the invocation of a named method.
@immutable
class MethodCall {
  /// Creates a [MethodCall] representing the invocation of [method] with the
  /// specified [arguments].
  const MethodCall(this.method, [this.arguments]);

  /// The name of the method to be called.
  final String method;

  /// The arguments for the method.
  ///
  /// Must be a valid value for the [MethodCodec] used.
  final dynamic arguments;

  @override
  String toString() => 'MethodCall($method $arguments)';
}

/// Default implementation
mixin MethodCallMixin implements MethodCall {
  @override
  dynamic get arguments => throw UnimplementedError();

  @override
  String get method => throw UnimplementedError();
}

class EventChannel {
  final _stream = BehaviorSubject<Object?>();
  final String name;

  EventChannel(this.name);

  Stream<Object?> receiveBroadcastStream() => _stream;
}

mixin EventChannelMixin implements EventChannel {
  @override
  String get name => throw UnimplementedError();

  @override
  Stream<Object?> receiveBroadcastStream() {
    throw UnimplementedError();
  }
}

class MethodChannel {
  final String name;

  const MethodChannel(this.name);

  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async {
    throw UnsupportedError('invokeMethod');
  }

  /// Sets a callback for receiving method calls on this channel.
  ///
  /// The given callback will replace the currently registered callback for this
  /// channel, if any. To remove the handler, pass null as the
  /// `handler` argument.
  ///
  /// If the future returned by the handler completes with a result, that value
  /// is sent back to the platform plugin caller wrapped in a success envelope
  /// as defined by the [codec] of this channel. If the future completes with
  /// a [PlatformException], the fields of that exception will be used to
  /// populate an error envelope which is sent back instead. If the future
  /// completes with a [MissingPluginException], an empty reply is sent
  /// similarly to what happens if no method call handler has been set.
  /// Any other exception results in an error envelope being sent.
  void setMethodCallHandler(
      Future<dynamic> Function(MethodCall call)? handler) {
    throw UnsupportedError('Unsupported');
  }
}

mixin MethodChannelMixin implements MethodChannel {
  @override
  Future invokeMethod(String method, [dynamic arguments]) {
    throw UnimplementedError();
  }

  @override
  String get name => throw UnimplementedError();

  @override
  void setMethodCallHandler(Future Function(MethodCall call)? handler) {}
}
