import 'dart:io';

import 'package:tekartik_bluetooth_server/src/bluetooth_server.dart';
import 'package:tekartik_bluetooth_server/src/bluetooth_server_client.dart';
import 'package:tekartik_bluetooth_server/src/import.dart';
import 'package:test/test.dart';

void main() {
  group('server', () {
    test('init', () async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      var server = await BluetoothServer.serve(
        webSocketChannelServerFactory: factory.server,
      );
      var client = await BluetoothServerClient.connect(
        server.url,
        webSocketChannelClientFactory: factory.client,
      );
      expect(client, isNotNull);

      await server.close();
    });

    test('server info platform', () async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      var server = await BluetoothServer.serve(
        webSocketChannelServerFactory: factory.server,
      );
      var client = await BluetoothServerClient.connect(
        server.url,
        webSocketChannelClientFactory: factory.client,
      );
      try {
        // Was always null: the server did not send them
        expect(client.serverInfo.isAndroid, Platform.isAndroid);
        expect(client.serverInfo.isIOS, Platform.isIOS);
      } finally {
        await client.close();
        await server.close();
      }
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
