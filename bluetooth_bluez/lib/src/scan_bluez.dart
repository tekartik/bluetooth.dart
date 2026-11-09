import 'package:bluez/bluez.dart';
import 'package:tekartik_bluetooth/uuid.dart';

import 'bluetooth_manager_bluez.dart';
import 'bluez_utils.dart';
import 'import.dart';
import 'import_bluetooth.dart';

abstract class BluetoothDeviceBluez extends BluetoothDevice {}

abstract class BluetoothDeviceIdBluez implements BluetoothDeviceId {}

/// Unique by address for now
class BluetoothDeviceIdBluezImpl
    with BluetoothDeviceIdMixin
    implements BluetoothDeviceIdBluez {
  final String address;

  BluetoothDeviceIdBluezImpl(this.address);

  @override
  String get id => address;
}

class BluetoothDeviceBluezImpl
    with BluetoothDeviceMixin
    implements BluetoothDeviceBluez {
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

  bool isScanning = false;

  final _lastScanData = <BluetoothDeviceId, ScanResultBluez>{};

  /// Starts the discovery on listen, stops it on cancel.
  ///
  /// With [withServices], BlueZ only discovers the devices advertising one of
  /// them, and the devices it already knows are filtered on their uuids.
  Stream<ScanResultBluez> startScan({List<Uuid128>? withServices}) {
    // Clear previous scan data
    // TODO keep recent items?

    _lastScanData.clear();
    var services = withServices?.toSet();
    var cancelled = false;
    late StreamController<ScanResultBluez> resultController;
    resultController = StreamController<ScanResultBluez>(
      onListen: () async {
        // A cancel during the start waits for it (same lock) then stops.
        await _scanLock.synchronized(() async {
          if (cancelled) {
            return;
          }
          try {
            // Connect first: the adapters are only known once connected.
            await bluezClient.connect();

            /// Start discovery
            var scanAdapters = _scanAdapters = <BlueZAdapter>[];
            for (var adapter in bluezClient.adapters) {
              try {
                // No uuids clears the filter of a previous scan.
                await adapter.setDiscoveryFilter(
                  uuids: services?.map((uuid) => uuid.toString()).toList(),
                );
              } catch (e) {
                _log('setDiscoveryFilter error $e');
              }
              try {
                await adapter.startDiscovery();
                scanAdapters.add(adapter);
              } catch (e) {
                _log('startDiscovery error $e');
              }
            }
            isScanning = true;
            void addDevice(BlueZDevice device) {
              if (services != null &&
                  !device.uuids.any(
                    (uuid) => services.contains(uuidFromBluezUuid(uuid)),
                  )) {
                return;
              }
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

            /// Add current devices
            addDevices(bluezClient.devices);
            addedSubscription = bluezClient.deviceAdded.listen(addDevice);
            removedSubscription = bluezClient.deviceRemoved.listen((device) {
              //data.removeDevice(device.address);
              // resultController.add(data);
            });
          } catch (e, st) {
            // No BlueZ (or no system bus): reported to the listener.
            resultController.addError(e, st);
          }
        });
      },
      onCancel: () async {
        cancelled = true;
        try {
          await _stopScan();
        } catch (_) {}
      },
    );

    return resultController.stream;
  }

  Future<void> _stopScan() async {
    await _scanLock.synchronized(() async {
      isScanning = false;
      addedSubscription?.cancel().unawait();
      addedSubscription = null;
      removedSubscription?.cancel().unawait();
      removedSubscription = null;
      var adapters = _scanAdapters;
      if (adapters?.isNotEmpty ?? false) {
        for (var adapter in adapters!) {
          try {
            await adapter.stopDiscovery();
          } catch (e) {
            _log('stopDiscovery error $e');
          }
        }
      }
      _scanAdapters = null;
    });
  }

  ScanResultBluez? getDeviceIdScanResult(BluetoothDeviceId deviceId) {
    return _lastScanData[deviceId];
  }

  void _log(Object? message) {
    // ignore: avoid_print
    print('/bluez $message');
  }
}
