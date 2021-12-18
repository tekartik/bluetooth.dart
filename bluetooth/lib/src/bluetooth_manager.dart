import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/bluetooth_state_service.dart';
import 'package:tekartik_bluetooth/src/options.dart';

class BluetoothPermissionsOptions {
  final int? androidRequestCode;
  final bool connect;
  final bool scan;
  final bool advertise;

  BluetoothPermissionsOptions(
      {this.androidRequestCode,
      this.connect = true,
      this.scan = true,

      /// Advertise is for simulating peripheral
      this.advertise = false});
}

abstract class BluetoothManagerCommon {
  bool? get isIOS;

  bool? get isAndroid;
}

mixin BluetoothManagerCommonMixin implements BluetoothManagerCommon {}

abstract class BluetoothAdminManager
    implements BluetoothManagerCommon, BluetoothStateService {
  @Deprecated('User checkBluetoothPermissions instead')
  Future<bool> checkCoarseLocationPermission({int? androidRequestCode});

  /// Android only
  ///
  /// Look for scan/connect permissiton for Android 12, location before
  Future<bool> checkBluetoothPermissions(
      {int? androidRequestCode, BluetoothPermissionsOptions? options});

  /// deprecated on purpose to remove from code.
  @Deprecated('Dev only')
  Future<void> devSetOptions(BluetoothOptions options);

  /// Get the info
  Future<BluetoothAdminInfo> getAdminInfo();
}

abstract class BluetoothManager
    implements
        BluetoothManagerCommon,

        /// Might be removed in the future...
        BluetoothStateService {
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
  BluetoothDeviceConnection newConnection(BluetoothDeviceId deviceId);

  /// For server side only
  Future<void> close();

  /// Get the info
  /// Only use scanning here!
  Future<BluetoothInfo> getInfo();
}

abstract class BluetoothServiceInvokable {
  Future<T> invokeMethod<T>(String method, [Object? arguments]);
}

abstract class BluetoothManagerImpl
    implements BluetoothManager, BluetoothServiceInvokable {}
