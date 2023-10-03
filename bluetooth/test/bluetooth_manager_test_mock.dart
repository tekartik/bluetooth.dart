import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/common/platform_mixin.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';

class BluetoothManagerTestMock
    with BluetoothManagerMixin, BluetoothManagerPlatformCompatMixin
    implements BluetoothManager {
  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) {
    // TODO: implement invokeMethod
    throw UnimplementedError();
  }
}
