import 'dart:async';
import 'dart:io';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/bluetooth_device_connection_flutter_blue.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/import.dart';
import 'package:tekartik_bluetooth_flutter_blue/utils/guid_utils.dart';

import 'bluetooth_device_flutter_blue.dart';
import 'flutter_blue_import.dart' as native;

class ScanResultFlutter implements ScanResult {
  final native.ScanResult nativeImpl;
  BluetoothDeviceFlutterBlue? _device;

  ScanResultFlutter(this.nativeImpl);

  @override
  BluetoothDevice get device =>
      _device ??= BluetoothDeviceFlutterBlue(nativeImpl.device);

  @override
  int get rssi => nativeImpl.rssi;

  @override
  String toString() => nativeImpl.toString();
}

class _ScanCacheDevice {
  final DateTime timestamp;
  final BluetoothDeviceFlutterBlue device;

  _ScanCacheDevice(this.timestamp, this.device);
}

class _ScanCache {
  final map = <BluetoothDeviceId, _ScanCacheDevice>{};

  BluetoothDeviceFlutterBlue? getDevice(BluetoothDeviceId deviceId) =>
      map[deviceId]?.device;

  void addDevice(BluetoothDeviceFlutterBlue device) {
    map[device.id] = _ScanCacheDevice(DateTime.now(), device);
  }
}

class BluetoothManagerFlutterBlue implements BluetoothManager {
  final _scanCache = _ScanCache();

  @Deprecated('Not flutter blue supported here')
  Future<bool> checkCoarseLocationPermission({int? androidRequestCode}) {
    throw UnimplementedError();
  }

  @Deprecated('Not flutter blue supported here')
  Future<bool> checkBluetoothPermissions({
    int? androidRequestCode,
    BluetoothPermissionsOptions? options,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    throw UnimplementedError();
  }

  @override
  Future disable() {
    throw UnimplementedError();
  }

  @override
  Future enable({int? requestCode, int? androidRequestCode}) {
    throw UnimplementedError();
  }

  @override
  Future<List<BluetoothDevice>> getConnectedDevices() async {
    var devices = native.FlutterBluePlus.connectedDevices;
    var blueDevices =
        devices.map((native) => BluetoothDeviceFlutterBlue(native)).toList();
    // cache
    for (var device in blueDevices) {
      _scanCache.addDevice(device);
    }
    return blueDevices;
  }

  @override
  Future<BluetoothInfo> getInfo() {
    throw UnimplementedError();
  }

  @override
  Future init() {
    throw UnimplementedError();
  }

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;

  @override
  Future<BluetoothDeviceConnection> newConnection(
    BluetoothDeviceId deviceId,
  ) async {
    var device = _scanCache.getDevice(deviceId);
    if (device == null) {
      throw StateError('Scan first before connecting to $deviceId');
    }
    return BluetoothDeviceConnectionFlutterBlue(device);
  }

  StreamSubscription? scannerSubscription;

  @override
  Stream<ScanResult> scan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Uuid128>? withServices,
  }) {
    scannerSubscription?.cancel();
    scannerSubscription = null;
    StreamController<ScanResult>? ctlr;
    var nativeServices =
        withServices?.map((e) => guidFromUuid(e)).toList() ?? <Guid>[];
    ctlr = StreamController<ScanResult>(
      onListen: () {
        scannerSubscription ??= native
            .FlutterBluePlusPrvExt.scanAndStreamResults(
          withServices: nativeServices,
        ).listen((nativeResult) {
          var scanResult = ScanResultFlutter(nativeResult);

          // cache
          _scanCache.addDevice(scanResult.device as BluetoothDeviceFlutterBlue);

          ctlr!.add(scanResult);
        });
      },
      onCancel: () {
        native.FlutterBlue.stopScan();
        scannerSubscription?.cancel();
        ctlr?.close();
      },
    );
    return ctlr.stream;
  }

  @override
  Future stop() async {
    await native.FlutterBlue.stopScan();
    /*
    unawaited(scannerSubscription?.cancel());
    scannerSubscription = null;

     */
  }

  @override
  // TODO: implement supportsEnable
  bool get supportsEnable => throw UnimplementedError();
}

final bluetoothManagerFlutterBlue = BluetoothManagerFlutterBlue();
