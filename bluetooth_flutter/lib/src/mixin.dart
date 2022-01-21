import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';

import 'client/connection.dart';
import 'import.dart';

class MixinTest with BluetoothFlutterManagerMixin, BluetoothManagerMixin {
  @override
  Future<T> invokeMethod<T>(String method, [arguments]) =>
      throw UnimplementedError();

  @override
  bool? get isAndroid => null;

  @override
  bool? get isIOS => null;
}

mixin BluetoothFlutterManagerMixin
    implements BluetoothFlutterManager, BluetoothManagerMixin {
  @override
  Future<BluetoothDeviceConnection> newConnection(
      BluetoothDeviceId deviceId) async {
    var connection = BluetoothDeviceConnectionFlutterImpl(manager: this);

    var map = <String, Object?>{};
    map['deviceId'] = deviceId;
    var result = await invokeMethod<dynamic>('remoteNewConnection', map);
    int? connectionId;
    if (result is int) {
      connectionId = result;
    } else if (result is Map) {
      // ? 2019-09-23 not used on Android
      connectionId = result[connectionIdKey] as int?;
    }
    connection.connectionId = connectionId;
    // print('newConnection success $connectionId');
    connections[connectionId] = connection;

    return connection;
  }
}
