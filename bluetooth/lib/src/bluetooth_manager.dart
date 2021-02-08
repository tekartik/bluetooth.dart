import 'package:tekartik_bluetooth/bluetooth_state_service.dart';
import 'package:tekartik_bluetooth/src/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/device_connection.dart';
import 'package:tekartik_bluetooth/src/info.dart';
import 'package:tekartik_bluetooth/src/options.dart';
import 'package:tekartik_bluetooth/src/scan_mode.dart';
import 'package:tekartik_bluetooth/src/scan_result.dart';

abstract class BluetoothManager extends BluetoothStateService {
  bool get isIOS;

  bool get isAndroid;

  /// deprecated on purpose to remove from code.
  @deprecated
  Future<void> devSetOptions(BluetoothOptions options);

  /// Get the info
  Future<BluetoothInfo> getInfo();

  // Android only
  Future<bool> checkCoarseLocationPermission({int androidRequestCode});

  Stream<ScanResult> scan({ScanMode scanMode = ScanMode.lowLatency});

  /// Good to call on start.
  ///
  /// On Android it handle hot restart by cancelling any pending scan
  Future init();

  /// Good to call on exit (WillPopScope).
  ///
  /// It will cancel any scan and device connection
  Future stop();

  Future<List<BluetoothDevice>> getConnectedDevices();

  /// Connect
  Future<BluetoothDeviceConnection> newConnection(String deviceId);

  /// For server side only
  Future<void> close();
}

abstract class BluetoothManagerImpl implements BluetoothManager {
  Future<T> invokeMethod<T>(String method, [dynamic arguments]);
}
