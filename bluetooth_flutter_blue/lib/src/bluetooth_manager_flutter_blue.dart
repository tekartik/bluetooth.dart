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

/// A [BluetoothManager] through flutter_blue_plus: scan, connections.
/// `init()`, `getInfo()`, `close()`, `enable()`, `disable()` and
/// `supportsEnable` throw `UnimplementedError`
/// (see `bluetoothAdminManagerFlutterBlue`).
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
    var blueDevices = devices
        .map((native) => BluetoothDeviceFlutterBlue(native))
        .toList();
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

  /// The native subscription of the current scan.
  StreamSubscription? scannerSubscription;

  StreamController<ScanResult>? _scanController;

  /// Scans until cancelled, [stop] or an error (given to the stream); a new
  /// scan replaces the running one (its stream ends). [scanMode] is ignored.
  @override
  Stream<ScanResult> scan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Uuid128>? withServices,
  }) {
    var nativeServices =
        withServices?.map((e) => guidFromUuid(e)).toList() ?? <Guid>[];
    // The previous scan ends (flutter_blue_plus restarts the native one).
    _scanController?.close();
    scannerSubscription?.cancel();
    scannerSubscription = null;
    late StreamController<ScanResult> controller;
    controller = StreamController<ScanResult>(
      onListen: () {
        // Listened after a newer scan replaced it: done already.
        if (_scanController != controller) {
          return;
        }
        scannerSubscription = native
            .flutterBluePlusScan(withServices: nativeServices)
            .listen(
              (nativeResult) {
                var scanResult = ScanResultFlutter(nativeResult);

                // cache
                _scanCache.addDevice(
                  scanResult.device as BluetoothDeviceFlutterBlue,
                );

                controller.add(scanResult);
              },
              onError: controller.addError,
              onDone: controller.close,
            );
      },
      onCancel: () async {
        // A scan replaced by a new one must not stop the new one (its native
        // subscription was cancelled by the new scan).
        if (_scanController == controller) {
          _scanController = null;
          var subscription = scannerSubscription;
          scannerSubscription = null;
          await subscription?.cancel();
          await native.FlutterBlue.stopScan();
        }
      },
    );
    _scanController = controller;
    return controller.stream;
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

/// The central manager through flutter_blue_plus (Android, iOS, macOS).
final bluetoothManagerFlutterBlue = BluetoothManagerFlutterBlue();
