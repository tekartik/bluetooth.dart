import 'package:tekartik_bluetooth/bluetooth_state_service.dart';
import 'package:tekartik_bluetooth_flutter/src/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter/src/client/connection.dart';
import 'package:tekartik_bluetooth_flutter/src/client/scan_mode.dart';
import 'package:tekartik_bluetooth_flutter/src/client/scan_result.dart';
import 'package:tekartik_bluetooth_flutter/src/manager.dart';
import 'package:tekartik_bluetooth_flutter/src/options.dart';

export 'package:tekartik_bluetooth_flutter/src/bluetooth_device.dart'
    show BluetoothDevice;
export 'package:tekartik_bluetooth_flutter/src/client/connection.dart'
    show
        BluetoothDeviceConnectionState,
        bluetoothDeviceConnectionStateDisconnecting,
        bluetoothDeviceConnectionStateConnecting,
        bluetoothDeviceConnectionStateConnected,
        bluetoothDeviceConnectionStateDisconnected,
        BluetoothDeviceConnection;
export 'package:tekartik_bluetooth_flutter/src/client/scan_result.dart'
    show ScanResult;
export 'package:tekartik_bluetooth_flutter/src/constant.dart'
    show bluetoothLogLevelVerbose, bluetoothLogLevelNone;
export 'package:tekartik_bluetooth_flutter/src/options.dart';

@Deprecated('Use [bluetoothManager] instead')
BluetoothFlutterManager get bluetoothService => bluetoothManager;
BluetoothFlutterManager get bluetoothManager => flutterBluetoothServiceImpl;

@Deprecated('Use [bluetoothService] instead')
BluetoothFlutterManager get flutterBluetoothService => bluetoothService;

abstract class BluetoothInfo {
  bool get hasBluetooth;

  bool get hasBluetoothBle;

  bool get isBluetoothEnabled;

  /// To handle Hot restart
  bool get isScanning;
}

abstract class BluetoothFlutterManager implements BluetoothStateService {
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
}
