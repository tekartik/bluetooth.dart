import 'package:dev_test/package.dart';

Future main() async {
  for (var dir in [
    // '.',
    'bluetooth',
    'bluetooth_flutter_blue',
    'bluetooth_server',
    'bluetooth_server_flutter',
    'bluetooth_server_app',
    'bluetooth_test',
    'bluetooth_test_app',
  ]) {
    await packageRunCi(dir);
  }
}
