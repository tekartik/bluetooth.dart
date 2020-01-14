import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tekartik_bluetooth/bluetooth_state_service.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter/src/constant.dart';
import 'package:tekartik_bluetooth_flutter/src/exception.dart';
import 'package:tekartik_bluetooth_flutter/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter/src/plugin.dart';
import 'package:tekartik_common_utils/bool_utils.dart';
import 'package:tekartik_common_utils/model/model.dart';

import 'import.dart';

class BluetoothInfoImpl implements BluetoothInfo {
  @override
  bool hasBluetooth;

  @override
  bool hasBluetoothBle;

  @override
  bool isBluetoothEnabled;

  @override
  bool isScanning;

  BluetoothInfoImpl(
      {this.hasBluetooth, this.hasBluetoothBle, this.isBluetoothEnabled});

  void fromMap(Map result) {
    var model = Model(result);
    hasBluetooth = parseBool(model['hasBluetooth']) ?? false;
    hasBluetoothBle = parseBool(model['hasBluetoothBle']) ?? false;
    isBluetoothEnabled = parseBool(model['isBluetoothEnabled']) ?? false;
    isScanning = parseBool(model['isScanning']) ?? false;
  }

  @override
  String toString() => toDebugMap().toString();
  Model toDebugMap() {
    var model = Model()
      ..setValue('hasBluetooth', hasBluetooth)
      ..setValue('hasBluetoothBle', hasBluetoothBle)
      ..setValue('isBluetoothEnabled', isBluetoothEnabled)
      ..setValue('isScanning', isScanning);
    return model;
  }
}

class BluetoothFlutterManagerImpl
    with BluetoothFlutterManagerMixin
    implements BluetoothStateService {
  final channel = bluetoothFlutterPlugin.methodChannel;

  BluetoothFlutterManagerImpl() {
    channel.setMethodCallHandler((MethodCall call) async {
      // devPrint('received ${call.method} ${call.arguments}');
      var connectionId = call.arguments[connectionIdKey] as int;
      if (connectionId != null) {
        var connection = connections[connectionId];
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
    final T result = await channel.invokeMethod(method, arguments) as T;
    return result;
  }

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;
}

final BluetoothFlutterManagerImpl flutterBluetoothServiceImpl =
    BluetoothFlutterManagerImpl();

BluetoothException test;
