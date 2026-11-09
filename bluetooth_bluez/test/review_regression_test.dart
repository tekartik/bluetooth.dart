@TestOn('linux')
library;

import 'dart:async';
import 'dart:io';

import 'package:bluez/bluez.dart';
import 'package:dbus/dbus.dart';
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_bluez/src/bluetooth_manager_bluez.dart';
import 'package:tekartik_bluetooth_bluez/src/connection_bluez.dart';
import 'package:tekartik_bluetooth_bluez/src/scan_bluez.dart';
import 'package:test/test.dart';

const _adapterInterface = 'org.bluez.Adapter1';
const _deviceInterface = 'org.bluez.Device1';
final _heartRateUuid = '0000180d-0000-1000-8000-00805f9b34fb';

/// A BlueZ adapter recording its discovery calls.
class _MockAdapter extends DBusObject {
  final calls = <String>[];
  var filter = <String, DBusValue>{};
  var discovering = false;

  _MockAdapter() : super(DBusObjectPath('/org/bluez/hci0'));

  @override
  Map<String, Map<String, DBusValue>> get interfacesAndProperties => {
    _adapterInterface: {
      'Address': const DBusString('00:00:00:00:00:01'),
      'Powered': const DBusBoolean(true),
      'Discovering': DBusBoolean(discovering),
      'UUIDs': DBusArray.string([]),
    },
  };

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == _adapterInterface) {
      calls.add(methodCall.name);
      switch (methodCall.name) {
        case 'SetDiscoveryFilter':
          filter = methodCall.values[0].asStringVariantDict();
          return DBusMethodSuccessResponse();
        case 'StartDiscovery':
          if (discovering) {
            return DBusMethodErrorResponse('org.bluez.Error.InProgress');
          }
          discovering = true;
          return DBusMethodSuccessResponse();
        case 'StopDiscovery':
          discovering = false;
          return DBusMethodSuccessResponse();
      }
    }
    return DBusMethodErrorResponse.unknownMethod();
  }
}

/// A BlueZ device.
class _MockDevice extends DBusObject {
  final String address;
  final List<String> uuids;
  final bool connected;

  _MockDevice(this.address, {this.uuids = const [], this.connected = false})
    : super(
        DBusObjectPath('/org/bluez/hci0/dev_${address.replaceAll(':', '_')}'),
      );

  @override
  Map<String, Map<String, DBusValue>> get interfacesAndProperties => {
    _deviceInterface: {
      'Adapter': DBusObjectPath('/org/bluez/hci0'),
      'Address': DBusString(address),
      'Name': DBusString('device $address'),
      'RSSI': const DBusInt16(-50),
      'UUIDs': DBusArray.string(uuids),
      'Connected': DBusBoolean(connected),
      'ServicesResolved': const DBusBoolean(false),
    },
  };
}

/// A BlueZ daemon on a private bus, the global [bluezClient] is connected to
/// it.
class _MockBlueZ {
  final _MockAdapter adapter;

  _MockBlueZ(this.adapter);

  static Future<_MockBlueZ> start({
    List<_MockDevice> devices = const [],
    bool bluez = true,
  }) async {
    var server = DBusServer();
    var address = await server.listenAddress(
      DBusAddress.unix(dir: Directory.systemTemp),
    );
    addTearDown(() => server.close());
    var bus = DBusClient(address);
    addTearDown(() => bus.close());
    var adapter = _MockAdapter();
    if (bluez) {
      await bus.requestName('org.bluez');
      await bus.registerObject(
        DBusObject(DBusObjectPath('/'), isObjectManager: true),
      );
      await bus.registerObject(adapter);
      for (var device in devices) {
        await bus.registerObject(device);
      }
    }
    var client = bluezClient = BlueZClient(bus: DBusClient(address));
    addTearDown(() => client.close());
    return _MockBlueZ(adapter);
  }
}

/// Waits for [condition], 2 seconds at most.
Future<void> _waitFor(bool Function() condition) async {
  var sw = Stopwatch()..start();
  while (!condition()) {
    if (sw.elapsed > const Duration(seconds: 2)) {
      fail('condition not met');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  test('the first scan starts the discovery', () async {
    var bluez = await _MockBlueZ.start();
    var manager = BluetoothManagerBluezImpl();
    var subscription = manager.scan().listen((_) {});
    await _waitFor(() => bluez.adapter.discovering);
    await subscription.cancel();
    await _waitFor(() => !bluez.adapter.discovering);
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('scan withServices', () async {
    var bluez = await _MockBlueZ.start(
      devices: [
        _MockDevice('00:00:00:00:00:0A', uuids: [_heartRateUuid]),
        _MockDevice('00:00:00:00:00:0B'),
      ],
    );
    var manager = BluetoothManagerBluezImpl();
    var addresses = <String>[];
    var subscription = manager
        .scan(withServices: [Uuid128(_heartRateUuid)])
        .listen((result) => addresses.add(result.device.address));
    await _waitFor(() => bluez.adapter.discovering);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(addresses, ['00:00:00:00:00:0A']);
    // BlueZ filters the discovery too.
    expect(bluez.adapter.filter['UUIDs'], DBusArray.string([_heartRateUuid]));
    await subscription.cancel();
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('a new scan while listening to the previous one', () async {
    var bluez = await _MockBlueZ.start(
      devices: [_MockDevice('00:00:00:00:00:0A')],
    );
    var manager = BluetoothManagerBluezImpl();
    var firstDone = Completer<void>();
    var secondDone = Completer<void>();
    var first = manager.scan().listen((_) {}, onDone: firstDone.complete);
    await _waitFor(() => bluez.adapter.discovering);
    var secondResults = <ScanResult>[];
    var second = manager.scan().listen(
      secondResults.add,
      onDone: secondDone.complete,
    );
    // The first scan ends.
    await firstDone.future.timeout(const Duration(seconds: 2));
    await _waitFor(() => secondResults.isNotEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // The second one goes on, discovering.
    expect(secondDone.isCompleted, isFalse);
    expect(bluez.adapter.discovering, isTrue);
    await first.cancel();
    await second.cancel();
    await _waitFor(() => !bluez.adapter.discovering);
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('a scan error reaches the listener', () async {
    // No BlueZ on the bus.
    await _MockBlueZ.start(bluez: false);
    var manager = BluetoothManagerBluezImpl();
    var error = Completer<Object>();
    var subscription = manager.scan().listen(
      (_) {},
      onError: (Object e) => error.complete(e),
    );
    expect(
      await error.future.timeout(const Duration(seconds: 2)),
      isA<DBusMethodResponseException>(),
    );
    await subscription.cancel();
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('discoverServices gives up when the services never resolve', () async {
    await _MockBlueZ.start(
      devices: [_MockDevice('00:00:00:00:00:0A', connected: true)],
    );
    await bluezClient.connect();
    var connection = BluetoothDeviceConnectionBluezImpl(
      BluetoothDeviceBluezImpl(bluezClient.devices.single),
    )..discoverServicesTimeout = const Duration(milliseconds: 300);
    await expectLater(
      connection.discoverServices().timeout(const Duration(seconds: 3)),
      throwsA(isA<StateError>()),
    );
  }, timeout: const Timeout(Duration(seconds: 10)));
}
