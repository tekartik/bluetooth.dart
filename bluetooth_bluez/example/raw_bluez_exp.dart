import 'package:dbus/dbus.dart';
import 'package:bluez/bluez.dart';

Future<void> main() async {
  var systemBus = DBusClient.system();
  var client = BlueZClient(systemBus);
  // ignore_for_file: await_only_futures
  await client.connect();

  print('Devices:');
  for (var device in client.devices) {
    print('  ${device.name} ${device.address}');
  }

  await systemBus.close();
}
