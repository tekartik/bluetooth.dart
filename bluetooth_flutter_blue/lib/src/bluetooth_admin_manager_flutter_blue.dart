import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:tekartik_app_platform/app_platform.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

class BluetoothAdminManagerFlutterBlue implements BluetoothAdminManager {
  @override
  Future<bool> checkBluetoothPermissions(
      {int? androidRequestCode, BluetoothPermissionsOptions? options}) async {
    // TODO: implement checkBluetoothPermissions
    throw UnimplementedError();
  }

  @override
  Future<bool> checkCoarseLocationPermission({int? androidRequestCode}) {
    // TODO: implement checkCoarseLocationPermission
    throw UnimplementedError();
  }

  @override
  // ignore: deprecated_member_use
  Future<void> devSetOptions(BluetoothOptions options) async {
    // TODO: implement devSetOptions
    //throw UnimplementedError();
  }

  @override
  Future disable() async {
    await FlutterBluePlus.instance.turnOff();
  }

  @override
  Future enable({int? requestCode, int? androidRequestCode}) async {
    await FlutterBluePlus.instance.turnOn();
    if (!((await getAdminInfo()).isBluetoothEnabled ?? false)) {
      throw StateError('Manual setup needed');
    }
    // TODO: implement enable
    // throw UnimplementedError();
  }

  @override
  Future<BluetoothAdminInfo> getAdminInfo() async {
    bool? available;
    bool? on;
    try {
      var instance = FlutterBluePlus.instance;
      try {
        await instance.state.first;
        available = await instance.isAvailable;
        // devPrint('blue available $available');
      } catch (e) {
        // ignore: avoid_print
        print('error $e getting flutter blue available');
      }
      try {
        on = await instance.isOn;
      } catch (e) {
        // ignore: avoid_print
        print('error $e getting flutter blue on');
      }
    } catch (e) {
      // ignore: avoid_print
      print('error $e getting flutter blue info');
    }
    var info = BluetoothAdminInfoImpl(
        hasBluetooth: available,
        hasBluetoothBle: available,
        isBluetoothEnabled: on);
    return info;
  }

  @override
  bool get isAndroid => platformContext.io?.isAndroid ?? false;

  @override
  // compat
  bool get isIOS => platformContext.io?.isIOS ?? false;

  @override
  bool get supportsEnable => isAndroid;
}

/// Implementation basic but only solution for iOS
final bluetoothAdminManagerFlutterBlue = BluetoothAdminManagerFlutterBlue();
