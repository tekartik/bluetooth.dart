import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/src/common/platform_mixin.dart';
import 'package:tekartik_bluetooth/src/import.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';

class BluetoothAdminManagerMock
    with BluetoothAdminManagerMixin, BluetoothManagerPlatformCompatMixin
    implements BluetoothAdminManager {
  @override
  Future<bool> checkCoarseLocationPermission({int? androidRequestCode}) async {
    return true;
  }

  @override
  Future<bool> checkBluetoothPermissions({
    int? androidRequestCode,
    BluetoothPermissionsOptions? options,
  }) async {
    return true;
  }

  @override
  Future disable() async {}

  @override
  Future enable({int? requestCode, int? androidRequestCode}) async {}

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) {
    // TODO: implement invokeMethod
    throw UnimplementedError();
  }

  @override
  bool? get supportsEnable => false;

  @override
  Future<BluetoothAdminInfo> getAdminInfo() async {
    return BluetoothAdminInfoImpl(
      hasBluetooth: true,
      hasBluetoothBle: true,
      isBluetoothEnabled: true,
    );
  }
}
