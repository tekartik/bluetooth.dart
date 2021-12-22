import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart' as web;
import 'package:tekartik_common_utils/common_utils_import.dart';

import 'import_bluetooth.dart';

abstract class BluetoothManagerWeb extends BluetoothManager
    implements BluetoothAdminManager {}

var debugBluetoothManagerWeb = false;

class BluetoothManagerWebImpl
    with BluetoothManagerMixin, BluetoothAdminManagerMixin
    implements BluetoothManagerWeb {
  /// Set upon start

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) {
    throw UnimplementedError();
  }

  @override
  Future<BluetoothInfo> getInfo() async {
    return BluetoothInfoImpl(
        hasBluetooth: true,
        hasBluetoothBle: true,
        isBluetoothEnabled:
            web.FlutterWebBluetooth.instance.isBluetoothApiSupported);
  }

  @override
  Future<BluetoothAdminInfo> getAdminInfo() async {
    return BluetoothAdminInfoImpl(
        hasBluetooth: true,
        hasBluetoothBle: true,
        isBluetoothEnabled:
            web.FlutterWebBluetooth.instance.isBluetoothApiSupported);
  }

  @override
  // TODO: implement isAndroid
  bool? get isAndroid => false;

  @override
  // TODO: implement isIOS
  bool? get isIOS => false;

  @override
  Stream<ScanResult> scan({ScanMode scanMode = ScanMode.lowLatency}) {
    /*
    scanController?.close();

    scanController = StreamController<ScanResult>(onCancel: () {
      _scanWebSubscription?.cancel();

      scanController?.close();
    }, onListen: () async {
      _scanService = ScanServicesWeb();
      _scanWebSubscription = _scanService?.startScan().listen((data) {
        scanController?.add(data);
      });
    });

    return scanController!.stream;

     */
    throw UnimplementedError();
  }

  // static int _connectionId = 0;
  @override
  Future<BluetoothDeviceConnection> newConnection(
      BluetoothDeviceId deviceId) async {
    /*
    var scanResult = _scanService?.getDeviceIdScanResult(deviceId);
    if (scanResult == null) {
      throw StateError('Device id $deviceId not found');
    }
    var connectionId = ++_connectionId;
    var connection = BluetoothDeviceConnectionWebImpl(
        scanResult.device as BluetoothDeviceWebImpl);

    connections[connectionId] = connection;

    return connection;*/
    throw UnimplementedError();
  }
}

/// Internal implementation
final BluetoothManagerWebImpl bluetoothManagerWebImpl =
    BluetoothManagerWebImpl();

/// Linux only
BluetoothManagerWeb get bluetoothManagerWeb => bluetoothManagerWebImpl;
