import 'package:tekartik_bluetooth_server/src/constant.dart';

String getBluetoothServerUrl({int? port}) {
  port ??= bluetoothServerDefaultPort;
  return 'ws://localhost:$port';
}
