import 'package:bluez/bluez.dart';
import 'package:dbus/dbus.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_bluez/src/connection_bluez.dart';
import 'package:tekartik_bluetooth_bluez/src/scan_bluez.dart';

import 'import.dart';

abstract class BluetoothManagerBluez extends BluetoothManager
    implements BluetoothAdminManager {}

bool debugBluetoothManagerBluez = false;
DBusClient systemBus = DBusClient.system();
BlueZClient bluezClient = BlueZClient(bus: systemBus);

class BluetoothManagerBluezImpl
    with BluetoothManagerMixin, BluetoothAdminManagerMixin
    implements BluetoothManagerBluez {
  ScanServicesBluez? _scanService;
  StreamSubscription? _scanBluezSubscription;

  /// Set upon start

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) {
    throw UnimplementedError();
  }

  Future<void> _ready() async {
    await bluezClient.connect();
  }

  @override
  Future<BluetoothAdminInfo> getAdminInfo() async {
    await _ready();
    return BluetoothAdminInfoImpl(
      hasBluetooth: true,
      hasBluetoothBle: true,
      isBluetoothEnabled: bluezClient.adapters.isNotEmpty,
    );
  }

  // Old
  @override
  Future<BluetoothInfo> getInfo() async {
    await _ready();
    return BluetoothInfoImpl(
      hasBluetooth: true,
      hasBluetoothBle: true,
      isBluetoothEnabled: bluezClient.adapters.isNotEmpty,
    )..isScanning = _scanService?.isScanning;
  }

  @override
  bool? get isAndroid => false;

  @override
  bool? get isIOS => false;

  @override
  Stream<ScanResult> scan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Uuid128>? withServices,
  }) {
    // Stop the previous scan before this one starts its discovery (BlueZ has
    // one discovery per D-Bus client).
    var previousStopped = _scanBluezSubscription?.cancel();
    _scanBluezSubscription = null;
    scanController?.close();

    late StreamController<ScanResult> controller;
    StreamSubscription<ScanResultBluez>? subscription;
    var cancelled = false;
    controller = StreamController<ScanResult>(
      onCancel: () async {
        // Only this scan's subscription: a previous scan closed by a new one
        // must not stop the new one.
        cancelled = true;
        if (_scanBluezSubscription == subscription) {
          _scanBluezSubscription = null;
        }
        await subscription?.cancel();
        if (scanController == controller) {
          scanController = null;
        }
      },
      onListen: () async {
        try {
          await previousStopped;
        } catch (_) {}
        if (cancelled) {
          return;
        }
        var scanService = _scanService = ScanServicesBluez();
        subscription = _scanBluezSubscription = scanService
            .startScan(withServices: withServices)
            .listen(controller.add, onError: controller.addError);
      },
    );
    scanController = controller;
    return controller.stream;
  }

  static int _connectionId = 0;
  @override
  Future<BluetoothDeviceConnection> newConnection(
    BluetoothDeviceId deviceId,
  ) async {
    var scanResult = _scanService?.getDeviceIdScanResult(deviceId);
    if (scanResult == null) {
      throw StateError('Device id $deviceId not found');
    }
    var connectionId = ++_connectionId;
    var connection = BluetoothDeviceConnectionBluezImpl(
      scanResult.device as BluetoothDeviceBluezImpl,
    );

    connections[connectionId] = connection;

    return connection;
  }
}

/// Internal implementation
final BluetoothManagerBluezImpl bluetoothManagerBluezImpl =
    BluetoothManagerBluezImpl();

/// The Linux manager (BlueZ over the D-Bus system bus), one instance for the
/// process.
BluetoothManagerBluez get bluetoothManagerBluez => bluetoothManagerBluezImpl;
