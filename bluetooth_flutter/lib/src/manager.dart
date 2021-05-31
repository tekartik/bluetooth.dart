import 'dart:io';

import 'package:tekartik_bluetooth/bluetooth_service.dart';
// ignore: implementation_imports
import 'package:tekartik_bluetooth/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_flutter/src/client/connection.dart';
import 'package:tekartik_bluetooth_flutter/src/constant.dart';
import 'package:tekartik_bluetooth_flutter/src/exception.dart';
import 'package:tekartik_bluetooth_flutter/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter/src/plugin.dart';

import 'import.dart';

class BluetoothFlutterManagerImpl
    with BluetoothFlutterManagerMixin, BluetoothManagerMixin
    implements BluetoothManager {
  final channel = bluetoothFlutterPlugin.methodChannel;

  BluetoothFlutterManagerImpl() {
    channel.setMethodCallHandler((MethodCall call) async {
      // devPrint('received ${call.method} ${call.arguments}');
      var argumentsMap = call.arguments as Map;
      var connectionId = argumentsMap[connectionIdKey] as int?;
      if (connectionId != null) {
        var connection =
            connections[connectionId] as BluetoothDeviceConnectionFlutterImpl?;
        if (connection == null) {
          print('cannot find connection $connectionId');
        } else {
          // Dispatch to connection
          connection.controller.add(call);
        }
      } else {
        var method = call.method;
        if (method == 'scanResult') {
          onScanResult(call.arguments);
        }
      }
    });
  }

  @override
  final bool supportsEnable = Platform.isAndroid;

  @override
  Future<T> invokeMethod<T>(String method, [arguments]) async {
    /*
    await channel.invokeMethod(method, arguments);
     */
    final result = await channel.invokeMethod(method, arguments) as T;
    return result;
  }

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;
}

final BluetoothFlutterManagerImpl flutterBluetoothServiceImpl =
    BluetoothFlutterManagerImpl();

BluetoothException? test;
