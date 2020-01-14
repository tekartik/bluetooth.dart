import 'dart:async';

import 'package:flutter/services.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter_peripheral.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter/src/plugin.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

export 'package:tekartik_bluetooth/bluetooth.dart';
export 'package:tekartik_bluetooth/bluetooth_state_service.dart';
export 'package:tekartik_bluetooth_flutter/src/constant.dart'
    show bluetoothLogLevelNone, bluetoothLogLevelVerbose;
export 'package:tekartik_bluetooth_flutter/src/options.dart'
    show
        // ignore: deprecated_member_use_from_same_package
        BluetoothOptions;

// TODO: do not expose
class BluetoothFlutter {
  static EventChannel get _connectionChannel =>
      bluetoothFlutterPlugin.connectionChannel;

  static bool _isSupported;

  static MethodChannel get _channel => bluetoothFlutterPlugin.methodChannel;

  static Future<String> get platformVersion async {
    final String version =
        (await _channel.invokeMethod('getPlatformVersion')) as String;
    return version;
  }

  static Future<bool> get _isSupportedReady async {
    return _isSupported ??=
        (await bluetoothManager.getInfo()).hasBluetoothBle ?? false;
  }

  /*
  static Future<blue.BluetoothState> get bluetoothState async {
    _isSupported ??= await _isSupportedReady;
    if (_isSupported) {
      return await blue.FlutterBlue.instance.state.first;
    } else {
      return BluetoothState.unavailable;
    }
  }
   */

  static final _enableLock = Lock();

  // Using a request code means explaining version
  static Future enableBluetooth({int requestCode}) async {
    _isSupported ??= await _isSupportedReady;
    assert(_isSupported, "call bluetoothState first");
    await _enableLock.synchronized(() async {
      await _channel.invokeMethod(
          'enableBluetooth', <String, dynamic>{'requestCode': requestCode});
    });
  }

  /// Occurs when the bluetooth state has changed
  static Stream<BluetoothFlutterSlaveConnection> onSlaveConnectionChanged() {
    return _connectionChannel.receiveBroadcastStream().map(
        (buffer) => BluetoothFlutterSlaveConnection()..fromMap(buffer as Map));
  }

  static Future startAdvertising({AdvertiseData advertiseData}) async {
    _isSupported ??= await _isSupportedReady;
    assert(_isSupported, "call bluetoothState first");

    await _channel.invokeMethod(
        'peripheralStartAdvertising', advertiseData?.toMap());
  }

  static Future stopAdvertising() async {
    _isSupported ??= await _isSupportedReady;
    assert(_isSupported, "call bluetoothState first");

    await _channel.invokeMethod('stopAdvertising', null);
  }

  static Future requireBluetoothAdmin({int requestCode}) async {
    _isSupported ??= await _isSupportedReady;
    assert(_isSupported, "call bluetoothState first");
    await _enableLock.synchronized(() async {
      await _channel.invokeMethod(
          'enableBluetooth', <String, dynamic>{'requestCode': requestCode});
    });
  }

  static Future disableBluetooth() async {
    _isSupported ??= await _isSupportedReady;
    assert(_isSupported, "call bluetoothStatus first");
    await _enableLock.synchronized(() async {
      await _channel.invokeMethod('disableBluetooth');
    });
  }

  static Future connect(String address) async {
    var map = <String, dynamic>{'address': address};
    await _channel.invokeMethod('connect', map);
  }

  static Future<BluetoothPeripheral> initPeripheral(
      {List<BluetoothGattService> services, String deviceName}) async {
    _isSupported ??= await _isSupportedReady;
    assert(_isSupported, "call bluetoothStatus first");

    var peripheral =
        BluetoothPeripheral(services: services, deviceName: deviceName);

    await _channel.invokeMethod('peripheralInit', peripheral.toMap());
    return peripheral;
  }
}
