import 'dart:async';

import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart' as web;
import 'package:tekartik_bluetooth_web/src/bluetooth_device_connection_web.dart';
import 'package:tekartik_bluetooth_web/src/bluetooth_manager_web.dart';
import 'package:tekartik_bluetooth_web/src/import_bluetooth.dart';
import 'package:test/test.dart';

/// A device whose GATT connection fails.
class _FailingDevice implements web.BluetoothDevice {
  @override
  Future<void> connect({Duration? timeout}) async {
    throw StateError('out of range');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // On the VM, flutter_web_bluetooth is its unsupported implementation (no
  // device): the scan streams stay open until cancelled.
  test('a new scan while listening to the previous one', () async {
    var manager = BluetoothManagerWebImpl();
    var firstDone = Completer<void>();
    var secondDone = Completer<void>();
    var first = manager.scan().listen((_) {}, onDone: firstDone.complete);
    var second = manager.scan().listen((_) {}, onDone: secondDone.complete);
    // The first scan ends.
    await firstDone.future.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // The second one must go on (the first one's cancel closed it).
    expect(secondDone.isCompleted, isFalse);
    expect(manager.scanController, isNotNull);
    await first.cancel();
    await second.cancel();
    expect(manager.scanController, isNull);
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('connect throws when the connection fails', () async {
    var connection = BluetoothDeviceConnectionWeb(_FailingDevice());
    var states = <BluetoothDeviceConnectionState>[];
    var subscription = connection.onConnectionState.listen(states.add);
    await expectLater(connection.connect(), throwsA(isA<StateError>()));
    await Future<void>.delayed(Duration.zero);
    expect(states, [
      BluetoothDeviceConnectionState.connecting,
      BluetoothDeviceConnectionState.disconnected,
    ]);
    await subscription.cancel();
  }, timeout: const Timeout(Duration(seconds: 10)));
}
