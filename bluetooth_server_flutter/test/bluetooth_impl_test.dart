import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_server/src/bluetooth_server.dart';
import 'package:tekartik_bluetooth_server_flutter/src/service_flutter.dart';
import 'package:tekartik_web_socket/web_socket.dart'; // ignore: depend_on_referenced_packages

T? _ambiguate<T>(T? value) => value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bluetooth_impl', () {
    const channel = MethodChannel('com.tekartik.bluetooth');

    final log = <MethodCall>[];
    String? response;

    _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      return response;
    });

    BluetoothManager? service;
    late BluetoothServer server;

    setUpAll(() async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      server = await BluetoothServer.serve(
          webSocketChannelServerFactory: factory.server);
      service = await BluetoothServerFlutterService.create(server.url,
          webSocketChannelClientFactory: factory.client);
    });

    test('port', () {
      expect(server.port, isNotNull);
      if (service != null) {
        expect(service!.isIOS, isNotNull);
      }
    });
    tearDownAll(() async {
      await server.close();
    });

    tearDown(() {
      log.clear();
    });

    /*
    test('getDatabasesPath', () async {
      response = 'path';
      var databasesPath = await databaseFactory.getDatabasesPath();
      expect(databasesPath, 'path');
    });

    test('deleteDatabase', () async {
      await databaseFactory.deleteDatabase('dummy');
    });

     */
  }, skip: true);
}
