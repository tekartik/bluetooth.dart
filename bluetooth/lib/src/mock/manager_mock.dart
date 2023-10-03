import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/common/platform_mixin.dart';
import 'package:tekartik_bluetooth/src/device_id.dart';
import 'package:tekartik_bluetooth/src/import.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';
import 'package:tekartik_bluetooth/src/mock/device_connection_mock.dart';
import 'package:tekartik_bluetooth/src/mock/peripheral_mock.dart';
import 'package:tekartik_bluetooth/src/uuid.dart';

import 'scan_result_mock.dart';

class BluetoothManagerMock
    with BluetoothManagerMixin, BluetoothManagerPlatformCompatMixin
    implements BluetoothManager {
  final BluetoothPeripheralMock? peripheral;
  List<BluetoothDevice> connectedDevices = [];
  bool isScanning = false;

  BluetoothManagerMock({required this.peripheral});
  @override
  Future<void> close() async {}

  @override
  Future disable() async {}

  @override
  Future enable({int? requestCode, int? androidRequestCode}) async {}

  @override
  Future<List<BluetoothDevice>> getConnectedDevices() async => connectedDevices;

  @override
  Future<BluetoothInfo> getInfo() async {
    return BluetoothInfoImpl(
        hasBluetooth: true,
        hasBluetoothBle: true,
        isBluetoothEnabled: true,
        isScanning: isScanning);
  }

  @override
  Future init() async {}

  @override
  Future<BluetoothDeviceConnection> newConnection(
      BluetoothDeviceId deviceId) async {
    return BluetoothDeviceConnectionMock(manager: this);
  }

  @override
  Stream<ScanResult> scan(
      {ScanMode scanMode = ScanMode.lowLatency,
      List<Uuid128>? withServices}) async* {
    try {
      isScanning = true;
      var peripheral = this.peripheral;
      if (peripheral != null) {
        var device = BluetoothDeviceImpl();
        device.id = BluetoothDeviceIdImpl('mock');
        device.name = 'Mock';
        yield ScanResultMock(device: device, rssi: 50);
      }
    } catch (_) {
      isScanning = false;
    }
  }

  @override
  Future stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }

  @override
  // TODO: implement supportsEnable
  bool? get supportsEnable => throw UnimplementedError();

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) =>
      throw UnsupportedError('invokeMethod($method)');
}
