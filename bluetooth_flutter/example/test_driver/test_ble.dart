import 'dart:async';

import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:test/test.dart';

@deprecated
Future devVerbose() async {
  /*
  // ignore: deprecated_member_use
  await bluetoothServiceSqflite.devSetOptions(
      // ignore: deprecated_member_use
      SqfliteOptions()..logLevel = sqfliteLogLevelVerbose);

   */
}

void main() {
  var manager = bluetoothManager;
  // final factory = databaseFactory as impl.SqfliteDatabaseFactoryMixin;
  group('impl', () {
    test('info', () async {
      var info = await manager.getInfo();
      print('info $info');
      if (info.hasBluetoothBle && info.isBluetoothEnabled) {
        StreamSubscription scanSubscription;
        try {
          scanSubscription = manager.scan().listen((scanResult) {
            print('scan: $scanResult');
          });
          info = await manager.getInfo();
          print('info $info');
          await Future.delayed(Duration(milliseconds: 5000));
        } catch (e) {
          print('startScan fail $e');
        } finally {
          scanSubscription?.cancel();
        }
      }
      info = await manager.getInfo();
      print('info $info');
    });
  });
}
