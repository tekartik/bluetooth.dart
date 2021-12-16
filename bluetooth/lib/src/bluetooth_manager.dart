import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/bluetooth_state_service.dart';
import 'package:tekartik_bluetooth/src/options.dart';

abstract class BluetoothManager extends BluetoothStateService {
  bool? get isIOS;

  bool? get isAndroid;

  /// deprecated on purpose to remove from code.
  @Deprecated('Dev only')
  Future<void> devSetOptions(BluetoothOptions options);

  /// Get the info
  Future<BluetoothInfo> getInfo();

  /// Android only
  ///
  /// Look for scan/connect permissiton for Android 12, location before
  Future<bool> checkBluetoothPermissions({int? androidRequestCode});
  // Android only
  Future<bool> checkCoarseLocationPermission({int? androidRequestCode});

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
  Future<BluetoothDeviceConnection> newConnection(BluetoothDeviceId deviceId);

  /// For server side only
  Future<void> close();
}

abstract class BluetoothManagerImpl implements BluetoothManager {
  Future<T> invokeMethod<T>(String method, [Object? arguments]);
}
