import 'package:tekartik_bluetooth_server/src/bluetooth_server.dart';
import 'package:tekartik_bluetooth_server/src/bluetooth_server_client.dart';
import 'package:tekartik_bluetooth_server/src/import.dart';
import 'package:test/test.dart';

void main() {
  group('server', () {
    test('init', () async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      var server = (await BluetoothServer.serve(
          webSocketChannelServerFactory: factory.server));
      var client = await BluetoothServerClient.connect(
        server.url,
        webSocketChannelClientFactory: factory.client,
      );
      expect(client, isNotNull);

      await server.close();
    });
  });
}
