// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:typed_data';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/battery.dart';
import 'package:tekartik_bluetooth/src/common/mixin_model.dart';
import 'package:tekartik_bluetooth/src/common/platform_mixin.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';
import 'package:tekartik_bluetooth/src/mock/battery_device.dart'
    show BatteryRemoteDevice;
import 'package:tekartik_bluetooth/src/mock/manager_mock.dart';
import 'package:tekartik_bluetooth/src/mock/peripheral_mock.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:test/test.dart';

/// Records the platform calls, `startScan` can fail.
class _Manager
    with BluetoothManagerMixin, BluetoothManagerPlatformCompatMixin
    implements BluetoothManager {
  final calls = <MapEntry<String, Object?>>[];
  Error? startScanError;

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) async {
    calls.add(MapEntry(method, arguments));
    if (method == methodStartScan && startScanError != null) {
      throw startScanError!;
    }
    return null as T;
  }
}

final _scanResultMap = <String, Object?>{
  'rssi': 10,
  'device': {'address': 'a', 'name': 'n'},
};

final _heartRateUuid = Uuid128('0000180d-0000-1000-8000-00805f9b34fb');

void main() {
  group('regression', () {
    test('scan withServices is sent', () async {
      var manager = _Manager();
      var subscription = manager
          .scan(withServices: [_heartRateUuid])
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(manager.calls.first.key, methodStartScan);
      expect(manager.calls.first.value, {
        'androidScanMode': 2,
        'serviceUuids': ['0000180d-0000-1000-8000-00805f9b34fb'],
      });
      await subscription.cancel();
      // Without services: no filter.
      manager.calls.clear();
      subscription = manager.scan().listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(manager.calls.first.value, {'androidScanMode': 2});
      await subscription.cancel();
    });

    test('a new scan while listening to the previous one', () async {
      var manager = _Manager();
      var firstDone = Completer<void>();
      var subscription1 = manager.scan().listen(
        (_) {},
        onDone: firstDone.complete,
      );
      await Future<void>.delayed(Duration.zero);
      var results = <ScanResult>[];
      var subscription2 = manager.scan().listen(results.add);
      await firstDone.future;
      await Future<void>.delayed(Duration.zero);
      manager.onScanResult(_scanResultMap);
      await Future<void>.delayed(Duration.zero);
      expect(results, hasLength(1));
      expect(manager.calls.map((call) => call.key), [
        methodStartScan,
        methodStartScan,
      ]);
      await subscription2.cancel();
      expect(manager.calls.last.key, methodStopScan);
      await subscription1.cancel();
    });

    test('startScan error reaches the listener', () async {
      var errors = <String>[];
      var done = Completer<void>();
      // ignore: unawaited_futures
      runZonedGuarded(
        () async {
          var manager = _Manager()..startScanError = StateError('adapter off');
          var subscription = manager.scan().listen(
            (_) {},
            onError: (Object e) => errors.add('listener $e'),
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await subscription.cancel();
          done.complete();
        },
        (e, _) {
          errors.add('uncaught $e');
          if (!done.isCompleted) {
            done.complete();
          }
        },
      );
      await done.future;
      expect(errors, ['listener Bad state: adapter off']);
    });

    test('Uuid128.from text of a non RFC 4122 uuid', () {
      // Nordic UART service
      var text = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
      expect(Uuid128.from(text: text), Uuid128(text));
      expect(Uuid128.from(text: text).toString(), text);
      expect(
        Uuid128.from(text: '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'),
        Uuid128(text),
      );
      expect(() => Uuid128.from(text: '180d'), throwsFormatException);
    });

    test('longNumberUuid32 compares the 4 bytes', () {
      var a = Uuid128('0000180d-0000-1000-8000-00805f9b34fb');
      var b = Uuid128('0000180e-0000-1000-8000-00805f9b34fb');
      expect(a.longNumberUuid32 == b.longNumberUuid32, isFalse);
      expect(
        a.longNumberUuid32 ==
            Uuid128('0000180d-1234-1000-8000-00805f9b34fb').longNumberUuid32,
        isTrue,
      );
      // 16 bit uuids unchanged
      expect(Uuid16.fromText('180D'), Uuid16.fromValue(0x180d));
      expect(a.shortNumberUuid16, Uuid16.fromValue(0x180d));
    });

    test('Uuid16 value of a byte view', () {
      var buffer = Uint8List.fromList([1, 2, 0x18, 0x0d]);
      var uuid = Uuid16.fromBytes(Uint8List.sublistView(buffer, 2));
      expect(uuid.value, 0x180d);
      expect(uuid, Uuid16.fromValue(0x180d));
      expect(uuid.hashCode, Uuid16.fromValue(0x180d).hashCode);
    });

    test('service created without characteristics', () {
      var service = BleBluetoothService(uuid: _heartRateUuid);
      expect(service.characteristics, isEmpty);
      // ignore: invalid_use_of_protected_member
      service.characteristics.add(
        BleBluetoothCharacteristic(service: service, uuid: _heartRateUuid),
      );
      expect(service.characteristics, hasLength(1));
    });

    test('battery remote device notifies its value', () async {
      var remote = BatteryRemoteDevice();
      var peripheral = BluetoothPeripheralMock(services: remote.gattServices);
      remote.bluetoothPeripheral = peripheral;
      var manager = BluetoothManagerMock(peripheral: peripheral);
      var connection = await manager.newConnection(BluetoothDeviceId('mock'));
      var bc = BleBluetoothCharacteristic(
        service: BleBluetoothService(uuid: batteryServiceUuid128),
        uuid: batteryServiceLevelCharacteristicUuid128,
      );
      var errors = <Object>[];
      var done = Completer<List<int>?>();
      // ignore: unawaited_futures
      runZonedGuarded(
        () async {
          var first = connection.onCharacteristicValueChanged(bc).first;
          await connection.registerCharacteristic(bc, true);
          await remote.notifyCharacteristicValue(
            bc.withValue(Uint8List.fromList([42])),
          );
          try {
            var value = await first.timeout(const Duration(seconds: 2));
            done.complete(value.value);
          } catch (_) {
            done.complete(null);
          }
        },
        (e, _) {
          errors.add(e);
        },
      );
      expect(await done.future, [42]);
      expect(errors, isEmpty);
      connection.close();
    });
  });
}
