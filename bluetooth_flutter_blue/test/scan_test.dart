import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_blue_plus_platform_interface/flutter_blue_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
// ignore: implementation_imports
import 'package:tekartik_bluetooth_flutter_blue/src/flutter_blue_import.dart'
    as native;

import 'src/fake_flutter_blue_plus.dart';

const _timeout = Duration(seconds: 5);

void main() {
  late FakeFlutterBluePlusPlatform fake;
  setUpAll(() {
    fake = FakeFlutterBluePlusPlatform();
    FlutterBluePlusPlatform.instance = fake;
  });
  tearDown(() async {
    await bluetoothManagerFlutterBlue.stop();
  });

  group('scan', () {
    test('gets the advertisements of the native scan', () async {
      var result = await bluetoothManagerFlutterBlue.scan().first.timeout(
        _timeout,
      );
      expect(
        result.device.id,
        BluetoothDeviceId(fakeScanDeviceId(fake.startScanCount)),
      );
      // Cached for newConnection.
      await bluetoothManagerFlutterBlue.newConnection(result.device.id);
    });

    test('stop ends the scan', () async {
      var done = Completer<void>();
      var first = Completer<void>();
      bluetoothManagerFlutterBlue.scan().listen(
        (_) => first.isCompleted ? null : first.complete(),
        onDone: done.complete,
      );
      await first.future.timeout(_timeout);
      expect(done.isCompleted, isFalse);
      await bluetoothManagerFlutterBlue.stop();
      await done.future.timeout(_timeout);
    });

    test('a new scan replaces the running one', () async {
      var firstDone = Completer<void>();
      bluetoothManagerFlutterBlue.scan().listen(
        (_) {},
        onDone: firstDone.complete,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      var result = await bluetoothManagerFlutterBlue.scan().first.timeout(
        _timeout,
      );
      // The advertisement of the new scan, the first stream ended.
      expect(
        result.device.id,
        BluetoothDeviceId(fakeScanDeviceId(fake.startScanCount)),
      );
      await firstDone.future.timeout(_timeout);
    });

    test('a start error reaches the listener', () async {
      fake.startScanError = PlatformException(code: 'denied');
      await expectLater(
        bluetoothManagerFlutterBlue.scan().first.timeout(_timeout),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('scanAndStreamResults', () {
    test('ends with the native scan, no result of a previous scan', () async {
      // A previous scan, with a result.
      var previous = await native.FlutterBluePlusPrvExt.scanAndStreamResults()
          .first
          .timeout(_timeout);
      await fbp.FlutterBluePlus.stopScan();

      var results = <fbp.ScanResult>[];
      var done = Completer<void>();
      var first = Completer<void>();
      native.FlutterBluePlusPrvExt.scanAndStreamResults().listen(
        (result) {
          results.add(result);
          if (!first.isCompleted) {
            first.complete();
          }
        },
        onDone: () {
          done.complete();
          if (!first.isCompleted) {
            first.completeError(StateError('done without result'));
          }
        },
      );
      await first.future.timeout(_timeout);
      expect(done.isCompleted, isFalse);
      // The advertisement of this scan only (not the previous one).
      expect(results.map((result) => result.device.remoteId.str), [
        fakeScanDeviceId(fake.startScanCount),
      ]);
      expect(results.single.device.remoteId, isNot(previous.device.remoteId));
      await fbp.FlutterBluePlus.stopScan();
      await done.future.timeout(_timeout);
    });
  });
}
