// A check against a real bluetooth server: a phone running
// bluetooth_server_app (`adb forward tcp:8502 tcp:8502`), skipped when no
// server answers. The url comes from the same defines as
// initBluetoothClientService, e.g.
// `flutter test --dart-define=TEKARTIK_BLUETOOTH_SERVER_PORT=8502`.
// ignore_for_file: implementation_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:tekartik_bluetooth_server/bluetooth_client.dart';
import 'package:tekartik_bluetooth_server_flutter/src/service_flutter.dart';

String get _serverUrl {
  const envUrl = String.fromEnvironment(bluetoothServerUrlEnvKey);
  const envPort = String.fromEnvironment(bluetoothServerPortEnvKey);
  return envUrl.isNotEmpty
      ? envUrl
      : getBluetoothServerUrl(port: int.tryParse(envPort));
}

void main() {
  group('example', () {
    BluetoothServerFlutterService? service;
    setUpAll(() async {
      service = await BluetoothServerFlutterService.create(_serverUrl);
    });

    tearDownAll(() async {
      await service?.close();
    });

    test('getInfo of the phone', () async {
      if (service == null) {
        markTestSkipped('no bluetooth server on $_serverUrl');
        return;
      }
      var info = await service!.getInfo();
      expect(info.hasBluetooth, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
