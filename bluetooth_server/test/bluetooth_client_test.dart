import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:test/test.dart';

// This test only works when the app is running
Future main() async {
  var service = await initBluetoothServerFlutterService();

  tearDownAll(() async {
    await service?.close();
  });

  group('client', () {
    test('init', () async {
      // var state =
      // await service.state;

      // await sqfliteServer.close();
    });
  }, skip: service == null);
}
