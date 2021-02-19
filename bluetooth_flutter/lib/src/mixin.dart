import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
// ignore: implementation_imports
import 'package:tekartik_bluetooth/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter/src/client/connection.dart';
import 'package:tekartik_bluetooth_flutter/src/constant.dart';
import 'package:tekartik_common_utils/model/model.dart';

import 'import.dart';

class MixinTest with BluetoothFlutterManagerMixin, BluetoothManagerMixin {
  @override
  Future<T> invokeMethod<T>(String method, [arguments]) => null;

  @override
  bool get isAndroid => null;

  @override
  bool get isIOS => null;
}

mixin BluetoothFlutterManagerMixin
    implements BluetoothFlutterManager, BluetoothManagerMixin {
  @override
  Future<BluetoothDeviceConnection> newConnection(
      BluetoothDeviceId deviceId) async {
    var connection = BluetoothDeviceConnectionFlutterImpl(manager: this);

    var map = Model();
    map['deviceId'] = deviceId;
    var result = await invokeMethod<dynamic>('remoteNewConnection', map);
    int connectionId;
    if (result is int) {
      connectionId = result;
    } else if (result is Map) {
      // ? 2019-09-23 not used on Android
      connectionId = result[connectionIdKey] as int;
    }
    connection.connectionId = connectionId;
    print('newConnection success $connectionId');
    connections[connectionId] = connection;

    return connection;
  }
}
