import 'package:bluez/bluez.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

import 'bluetooth_manager_bluez.dart';

abstract class BluetoothDeviceBluez extends BluetoothDevice {}

abstract class BluetoothDeviceIdBluez extends BluetoothDeviceId {}

/// Unique by address for now
class BluetoothDeviceIdBluezImpl
    with BluetoothDeviceIdMixin
    implements BluetoothDeviceIdBluez {
  final String address;

  BluetoothDeviceIdBluezImpl(this.address);

  @override
  String get id => address;
}

class BluetoothDeviceBluezImpl implements BluetoothDeviceBluez {
  final BlueZDevice blueZDevice;

  BluetoothDeviceBluezImpl(this.blueZDevice);

  @override
  String get address => blueZDevice.address;

  @override
  BluetoothDeviceIdBluezImpl get id => BluetoothDeviceIdBluezImpl(address);

  @override
  String? get name => blueZDevice.name;

  @override
  String toString() => '$name($address)';
}

abstract class ScanResultBluez implements ScanResult {}

class ScanResultBluezImpl implements ScanResultBluez {
  @override
  final BluetoothDeviceBluezImpl device;

  @override
  int get rssi => device.blueZDevice.rssi;

  ScanResultBluezImpl(this.device);

  @override
  String toString() => 'rssi:$rssi $device';
}

class ScanServicesBluez {
  List<BlueZAdapter>? _scanAdapters;

  StreamSubscription? addedSubscription;
  StreamSubscription? removedSubscription;

  final _scanLock = Lock();

  var isScanning = false;

  final _lastScanData = <BluetoothDeviceId, ScanResultBluez>{};

  Stream<ScanResultBluez> startScan() {
    // Clear previous scan data
    // TODO keep recent items?

    _lastScanData.clear();
    late StreamController<ScanResultBluez> resultController;
    resultController = StreamController<ScanResultBluez>(onListen: () async {
      try {
        await _stopScan();
      } catch (_) {}

      /// Start discovery
      _scanAdapters = <BlueZAdapter>[];

      var adapters = bluezClient.adapters;
      await bluezClient.connect();
      for (var adapter in adapters) {
        try {
          /// Add current devices

          await adapter.startDiscovery();
          _scanAdapters!.add(adapter);
        } catch (e) {
          print('startDiscovery error $e');
        }
      }
      isScanning = true;
      void addDevice(BlueZDevice device) {
        var deviceBluez = BluetoothDeviceBluezImpl(device);
        var scanResultBluez = ScanResultBluezImpl(deviceBluez);
        resultController.add(scanResultBluez);
        _lastScanData[deviceBluez.id] = scanResultBluez;
      }

      void addDevices(List<BlueZDevice> devices) {
        for (var device in devices) {
          addDevice(device);
        }
      }

      addDevices(bluezClient.devices);
      addedSubscription = bluezClient.deviceAdded.listen((device) {
        addDevice(device);
      });
      removedSubscription = bluezClient.deviceRemoved.listen((device) {
        //data.removeDevice(device.address);
        // resultController.add(data);
      });
      // add current data
    }, onCancel: () async {
      try {
        await _stopScan();
      } catch (_) {}
    });

    return resultController.stream;
  }

  Future<void> _stopScan() async {
    isScanning = false;
    addedSubscription?.cancel().unawait();
    addedSubscription = null;
    removedSubscription?.cancel().unawait();
    removedSubscription = null;

    await _scanLock.synchronized(() async {
      var adapters = _scanAdapters;
      if (adapters?.isNotEmpty ?? false) {
        for (var adapter in adapters!) {
          try {
            await adapter.stopDiscovery();
          } catch (e) {
            print('stopDiscovery error $e');
          }
        }
      }
    });
  }

  ScanResultBluez? getDeviceIdScanResult(BluetoothDeviceId deviceId) {
    return _lastScanData[deviceId];
  }
}
