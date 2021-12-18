import 'package:bluez/bluez.dart';
import 'package:dbus/dbus.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_bluetooth_bluez/src/connection_bluez.dart';
import 'package:tekartik_bluetooth_bluez/src/scan_bluez.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

abstract class BluetoothManagerBluez extends BluetoothManager
    implements BluetoothAdminManager {}

var debugBluetoothManagerBluez = false;
var systemBus = DBusClient.system();
var bluezClient = BlueZClient(bus: systemBus);

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
  Future<BluetoothInfo> getInfo() async {
    await _ready();
    return BluetoothInfoImpl(
        hasBluetooth: true,
        hasBluetoothBle: true,
        isBluetoothEnabled: bluezClient.adapters.isNotEmpty)
      ..isScanning = _scanService?.isScanning;
  }

  @override
  // TODO: implement isAndroid
  bool? get isAndroid => false;

  @override
  // TODO: implement isIOS
  bool? get isIOS => false;

  @override
  Stream<ScanResult> scan({ScanMode scanMode = ScanMode.lowLatency}) {
    scanController?.close();

    scanController = StreamController<ScanResult>(onCancel: () {
      _scanBluezSubscription?.cancel();

      scanController?.close();
    }, onListen: () async {
      _scanService = ScanServicesBluez();
      _scanBluezSubscription = _scanService?.startScan().listen((data) {
        scanController?.add(data);
      });
    });

    return scanController!.stream;
  }

  static int _connectionId = 0;
  @override
  BluetoothDeviceConnection newConnection(BluetoothDeviceId deviceId) {
    var scanResult = _scanService?.getDeviceIdScanResult(deviceId);
    if (scanResult == null) {
      throw StateError('Device id $deviceId not found');
    }
    var connectionId = ++_connectionId;
    var connection = BluetoothDeviceConnectionBluezImpl(
        scanResult.device as BluetoothDeviceBluezImpl);

    connections[connectionId] = connection;

    return connection;
  }
}

/// Internal implementation
final BluetoothManagerBluezImpl bluetoothManagerBluezImpl =
    BluetoothManagerBluezImpl();

/// Linux only
BluetoothManagerBluez get bluetoothManagerBluez => bluetoothManagerBluezImpl;
