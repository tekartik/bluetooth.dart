// ignore_for_file: avoid_print

import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:tekartik_bluetooth_server/bluetooth_server.dart';

Future<void> main() async {
  // On the phone, serverBluetoothManager must be set first (the Flutter
  // plugin manager): every remote call is forwarded to it.
  var server = await BluetoothServer.serve(port: 0); // 0: a free port
  var context = await BluetoothServerContext.connect(server.url);
  print('connected to ${server.url}, android: ${context?.isAndroid}');
  await context?.close();
  await server.close();
}
