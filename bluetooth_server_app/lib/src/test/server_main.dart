
import 'package:tekartik_bluetooth_server_app/src/import.dart';

int defaultPort = bluetoothServerDefaultPort;

void main() {
  menu('server', () {
    BluetoothServer? server;
    item('start', () async {
      server ??= await BluetoothServer.serve(port: defaultPort);
    });
    item('stop', () async {
      await server?.close();
      server = null;
    });
  });
}
