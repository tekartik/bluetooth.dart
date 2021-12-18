import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/common/mixin_model.dart';
import 'package:tekartik_bluetooth/src/constant.dart';
import 'package:tekartik_bluetooth/src/options.dart';
import 'package:tekartik_common_utils/map_utils.dart';

import 'bluetooth_device.dart';
import 'import.dart';

export 'common/device_connection_mixin.dart';
export 'common/device_mixin.dart';

const methodCheckBluetoothPermissions = 'checkBluetoothPermissions';

const requestCodeEnableBluetoothDefault = 30123;
const requestCodeCheckBluetoothPermissions = 30124;

class MixinTest with BluetoothManagerMixin {
  @override
  Future<T> invokeMethod<T>(String method, [arguments]) =>
      throw UnimplementedError();

  @override
  bool? get isAndroid => null;

  @override
  bool? get isIOS => null;
}

mixin BluetoothAdminManagerMixin
    implements BluetoothAdminManager, BluetoothServiceInvokable {
  @override
  Future<bool> checkBluetoothPermissions(
      {int? androidRequestCode, BluetoothPermissionsOptions? options}) async {
    androidRequestCode ??= requestCodeCheckBluetoothPermissions;
    return await invokeMethod<bool>(
        methodCheckBluetoothPermissions, <String, dynamic>{
      'androidRequestCode': androidRequestCode,
      if (options?.advertise ?? false) 'advertise': true
    });
  }

  @override
  // ignore: deprecated_member_use_from_same_package
  Future<void> devSetOptions(BluetoothOptions options) async {
    await invokeMethod<dynamic>(methodSetOptions, options.toMap());
  }

  @override
  Future<BluetoothAdminInfo> getAdminInfo() async {
    var result = await invokeMethod<Map>('getAdminInfo');

    var info = BluetoothAdminInfoImpl()..fromMap(result);
    return info;
  }
}
mixin BluetoothManagerMixin implements BluetoothManager {
  final connections = <int?, BluetoothDeviceConnection>{};

  Future<T> invokeMethod<T>(String method, [Object? arguments]);

  @override
  bool? get supportsEnable => isAndroid;

  @override
  Future<BluetoothInfo> getInfo() async {
    var result = await invokeMethod<Map>('getInfo');

    var info = BluetoothInfoImpl()..fromMap(result);
    return info;
  }

  @override
  Future init() async {
    BluetoothInfo? info;
    try {
      info = await getInfo();
      if (info.isScanning!) {
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
    BluetoothInfo? info;
    try {
      info = await getInfo();
      if (info.isScanning!) {
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
    return result
        .map((item) => asMap(item))
        .where((map) => map != null)
        .map((map) => BluetoothDeviceImpl()..fromMap(map))
        .toList(growable: false);
  }

  @override
  Future enable(
      {@Deprecated('Use androidRequestCode') int? requestCode,
      int? androidRequestCode}) async {
    androidRequestCode ??= requestCode ?? requestCodeEnableBluetoothDefault;
    // Using a request code means explaining version

    await invokeMethod('enableBluetooth',
        <String, dynamic>{'androidRequestCode': androidRequestCode});
  }

  Future<bool> checkCoarseLocationPermission({int? androidRequestCode}) async {
    androidRequestCode ??= requestCodeCheckBluetoothPermissions;
    return await invokeMethod<bool>('checkCoarseLocationPermission',
        <String, dynamic>{'androidRequestCode': androidRequestCode});
  }

  @override
  Future disable() async {
    await invokeMethod('disableBluetooth');
  }

  Future invokeStopScan() async {
    await invokeMethod<dynamic>('stopScan');
  }

  StreamController<ScanResult>? scanController;

  @override
  Stream<ScanResult> scan({ScanMode scanMode = ScanMode.lowLatency}) {
    var param = StartScanParam()..androidScanMode.v = scanMode.value;
    var map = param.toMap();

    scanController?.close();

    scanController = StreamController<ScanResult>(onCancel: () async {
      scanController = null;
      await invokeStopScan();
    });
    () async {
      await invokeMethod<dynamic>(methodStartScan, map);
    }();
    return scanController!.stream;
  }

  void onScanResult(dynamic map) {
    if (map is Map && scanController != null) {
      var scanResult = ScanResultImpl()..fromMap(map);
      scanController!.add(scanResult);
    }
  }

  @override
  BluetoothDeviceConnection newConnection(BluetoothDeviceId deviceId) =>
      throw UnimplementedError('newConnection');

  @override
  Future<void> close() async {
    //throw UnimplementedError();
  }
}
