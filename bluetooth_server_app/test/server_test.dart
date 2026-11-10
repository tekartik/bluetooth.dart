// ignore_for_file: implementation_imports
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth_server/src/service.dart';
import 'package:tekartik_bluetooth_server_app/src/app.dart';

const _channel = MethodChannel('tekartik_bluetooth_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('remote calls reach the Bluetooth plugin of the phone', () async {
    var messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // The plugin of the phone.
    messenger.setMockMethodCallHandler(_channel, (call) async {
      if (call.method == 'getInfo') {
        return {
          'hasBluetooth': true,
          'hasBluetoothBle': true,
          'isBluetoothEnabled': true,
          'isScanning': false,
        };
      }
      return null;
    });
    var app = App();
    var server = await app.startServer(0);
    var client = await BluetoothServerService.create(server.url);
    try {
      // Was a LateInitializationError: serverBluetoothManager never set.
      var info = await client!.getInfo();
      expect(info.hasBluetoothBle, isTrue);
      expect(info.isBluetoothEnabled, isTrue);
    } finally {
      await client?.close();
      await app.stopServer();
      messenger.setMockMethodCallHandler(_channel, null);
    }
  }, timeout: const Timeout(Duration(seconds: 20)));
}
