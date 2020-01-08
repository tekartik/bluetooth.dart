import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart'
    show BluetoothState;
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter/src/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter/src/client/connection.dart';
import 'package:tekartik_bluetooth_flutter/src/client/scan_mode.dart';
import 'package:tekartik_bluetooth_flutter/src/client/scan_result.dart';
import 'package:tekartik_bluetooth_flutter/src/constant.dart';
import 'package:tekartik_bluetooth_flutter/src/manager.dart';
import 'package:tekartik_bluetooth_flutter/src/options.dart';
import 'package:tekartik_common_utils/map_utils.dart';
import 'package:tekartik_common_utils/model/model.dart';

import 'import.dart';

class MixinTest with BluetoothFlutterManagerMixin {
  @override
  Future<T> invokeMethod<T>(String method, [arguments]) => null;

  @override
  bool get isAndroid => null;

  @override
  bool get isIOS => null;

  @override
  Future<BluetoothState> get state => null;
}

mixin BluetoothFlutterManagerMixin implements BluetoothFlutterManager {
  final connections = <int, BluetoothDeviceConnectionImpl>{};

  Future<T> invokeMethod<T>(String method, [dynamic arguments]);

  @override
  bool get supportsEnable => isAndroid;

  @override
  Future<BluetoothInfo> getInfo() async {
    var result = await invokeMethod<Map>('getInfo');
    if (result is Map) {
      var info = BluetoothInfoImpl()..fromMap(result);
      return info;
    }
    return null;
  }

  @override
  Future init() async {
    BluetoothInfo info;
    try {
      info = await getInfo();
      if (info.isScanning) {
        await invokeStopScan();
        info = await getInfo();
        // devPrint(info);
      }
      var connectedDevices = await getConnectedDevices();
      if (isDebug) {
        print(connectedDevices);
      }
    } catch (e) {
      print('getInfo failed $e');
    }
  }

  @override
  Future stop() async {
    BluetoothInfo info;
    try {
      info = await getInfo();
      if (info.isScanning) {
        try {
          await invokeStopScan();
        } catch (e) {
          print('invokeStopScan failed $e');
        }
        try {
          info = await getInfo();
          // devPrint(info);
        } catch (e) {
          print('getInfo failed $e');
        }
      }

      try {
        var connectedDevices = await getConnectedDevices();
        if (isDebug) {
          print(connectedDevices);
        }
      } catch (e) {
        print('getConnectedDevices failed $e');
      }
    } catch (e) {
      print('getInfo failed $e');
    }
  }

  @override
  Future<List<BluetoothDevice>> getConnectedDevices() async {
    var result = await invokeMethod<Iterable>('getConnectedDevices');
    if (result is Iterable) {
      return result
          .map((item) => asMap(item))
          .where((map) => map != null)
          .map((map) => BluetoothDeviceImpl()..fromMap(map))
          .toList(growable: false);
    }
    return null;
  }

  @override
  Future enable({int requestCode, int androidRequestCode}) async {
    androidRequestCode ??= requestCode;
    // Using a request code means explaining version

    await invokeMethod('enableBluetooth',
        <String, dynamic>{'androidRequestCode': androidRequestCode});
  }

  @override
  Future<bool> checkCoarseLocationPermission({int androidRequestCode}) async {
    return await invokeMethod<bool>('checkCoarseLocationPermission',
        <String, dynamic>{'androidRequestCode': androidRequestCode});
  }

  @override
  Future disable() async {
    await invokeMethod('disableBluetooth');
  }

  @override
  // ignore: deprecated_member_use_from_same_package
  Future<void> devSetOptions(BluetoothOptions options) async {
    await invokeMethod<dynamic>(methodSetOptions, options.toMap());
  }

  Future invokeStopScan() async {
    await invokeMethod<dynamic>('stopScan');
  }

  StreamController<ScanResult> scanController;

  @override
  Stream<ScanResult> scan({ScanMode scanMode = ScanMode.lowLatency}) {
    var map = Model();
    map['androidScanMode'] = scanMode.value;

    scanController?.close();

    scanController = StreamController<ScanResult>(onCancel: () async {
      scanController = null;
      await invokeStopScan();
    });
    () async {
      await invokeMethod<dynamic>('startScan', map);
    }();
    return scanController.stream;
  }

  void onScanResult(dynamic map) {
    if (map is Map && scanController != null) {
      var scanResult = ScanResultImpl()..fromMap(map);
      scanController.add(scanResult);
    }
  }

  @override
  Future<BluetoothDeviceConnection> newConnection(String deviceId) async {
    var connection = BluetoothDeviceConnectionImpl(manager: this);

    var map = Model();
    map['deviceId'] = deviceId;
    var result = await invokeMethod<dynamic>('remoteNewConnection', map);
    int connectionId;
    if (result is int) {
      connectionId = result;
    } else if (result is Map) {
      // ? 2019-09-23 not used on Android
      connectionId = result[connectionIdKey] as int;
    }
    connection.connectionId = connectionId;
    print('newConnection success $connectionId');
    connections[connectionId] = connection;

    return connection;
  }
}
