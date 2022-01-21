import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';

class BluetoothManagerTestMock
    with BluetoothManagerMixin
    implements BluetoothManager {
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
}
