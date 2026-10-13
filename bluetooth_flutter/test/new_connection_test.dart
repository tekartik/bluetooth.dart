// ignore_for_file: implementation_imports
import 'package:flutter/services.dart' as services;
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter/src/mixin.dart';

/// Encodes every call like the platform channel does.
class _Manager with BluetoothManagerMixin, BluetoothFlutterManagerMixin {
  final arguments = <Object?>[];

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) async {
    const services.StandardMethodCodec().encodeMethodCall(
      services.MethodCall(method, arguments),
    );
    this.arguments.add(arguments);
    return 1 as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('newConnection sends the device id as a string', () async {
    var manager = _Manager();
    var connection = await manager.newConnection(
      BluetoothDeviceId('00:11:22:33:44:55'),
    );
    expect(manager.arguments, [
      {'deviceId': '00:11:22:33:44:55'},
    ]);
    expect(manager.connections[1], connection);
  });
}
