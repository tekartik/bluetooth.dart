import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth_flutter/src/manager.dart';

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

/// Deprecated Use bluetoothManagerFlutter
@Deprecated('Use bluetoothManagerFlutter')
BluetoothFlutterManager get bluetoothManager => bluetoothManagerFlutter;

/// Bluetooth manager for flutter, experimental
BluetoothFlutterManager get bluetoothManagerFlutter =>
    flutterBluetoothServiceImpl;

/// Admin manager, ok for Android, not for iOS
BluetoothAdminManager get bluetoothAdminManagerFlutter =>
    flutterBluetoothServiceImpl;
@Deprecated('Use [bluetoothManager] instead')
BluetoothFlutterManager get flutterBluetoothService => bluetoothService;

abstract class BluetoothFlutterManager implements BluetoothManager {}
