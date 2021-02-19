import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/options.dart';
import 'package:tekartik_bluetooth/src/scan_result.dart';

class BluetoothManagerTestMock
    with BluetoothManagerMixin
    implements BluetoothManager {}

mixin BluetoothManagerMixin implements BluetoothManager {
  @override
  Future<bool> checkCoarseLocationPermission({int androidRequestCode}) {
    // TODO: implement checkCoarseLocationPermission
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  // ignore: deprecated_member_use_from_same_package
  Future<void> devSetOptions(BluetoothOptions options) {
    // TODO: implement devSetOptions
    throw UnimplementedError();
  }

  @override
  Future disable() {
    // TODO: implement disable
    throw UnimplementedError();
  }

  @override
  Future enable({int requestCode, int androidRequestCode}) {
    // TODO: implement enable
    throw UnimplementedError();
  }

  @override
  Future<List<BluetoothDevice>> getConnectedDevices() {
    // TODO: implement getConnectedDevices
    throw UnimplementedError();
  }

  @override
  Future<BluetoothInfo> getInfo() {
    // TODO: implement getInfo
    throw UnimplementedError();
  }

  @override
  Future init() {
    // TODO: implement init
    throw UnimplementedError();
  }

  @override
  // TODO: implement isAndroid
  bool get isAndroid => throw UnimplementedError();

  @override
  // TODO: implement isIOS
  bool get isIOS => throw UnimplementedError();

  @override
  Future<BluetoothDeviceConnection> newConnection(BluetoothDeviceId deviceId) {
    // TODO: implement newConnection
    throw UnimplementedError();
  }

  @override
  Stream<ScanResult> scan({ScanMode scanMode = ScanMode.lowLatency}) {
    // TODO: implement scan
    throw UnimplementedError();
  }

  @override
  Future stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }

  @override
  // TODO: implement supportsEnable
  bool get supportsEnable => throw UnimplementedError();
}
