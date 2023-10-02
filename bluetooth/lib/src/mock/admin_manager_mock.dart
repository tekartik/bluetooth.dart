import 'dart:io';

import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/src/import.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';

mixin BluetoothManagerPlatformCompatMixin {
  bool? get isAndroid => isRunningAsJavascript ? false : Platform.isAndroid;

  bool? get isIOS => isRunningAsJavascript ? false : Platform.isIOS;
}

class BluetoothAdminManagerMock
    with BluetoothAdminManagerMixin, BluetoothManagerPlatformCompatMixin
    implements BluetoothAdminManager {
  @override
  Future<bool> checkCoarseLocationPermission({int? androidRequestCode}) {
    // TODO: implement checkCoarseLocationPermission
    throw UnimplementedError();
  }

  @override
  Future disable() {
    // TODO: implement disable
    throw UnimplementedError();
  }

  @override
  Future enable({int? requestCode, int? androidRequestCode}) {
    // TODO: implement enable
    throw UnimplementedError();
  }

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) {
    // TODO: implement invokeMethod
    throw UnimplementedError();
  }

  @override
  // TODO: implement isAndroid
  bool? get isAndroid => throw UnimplementedError();

  @override
  // TODO: implement isIOS
  bool? get isIOS => throw UnimplementedError();

  @override
  // TODO: implement supportsEnable
  bool? get supportsEnable => throw UnimplementedError();

  @override
  Future<BluetoothAdminInfo> getAdminInfo() async {
    return BluetoothAdminInfoImpl(
        hasBluetooth: true, hasBluetoothBle: true, isBluetoothEnabled: true);
  }
}
