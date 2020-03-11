import 'package:tekartik_bluetooth_server/bluetooth_server.dart';
import 'package:tekartik_test_menu/test.dart';

int defaultPort = bluetoothServerDefaultPort;
void main() {
  menu('server', () {
    BluetoothServer server;
    item('start', () async {
      server ??= await BluetoothServer.serve(port: defaultPort);
    });
    item('stop', () async {
      await server?.close();
      server = null;
    });
  });
}
