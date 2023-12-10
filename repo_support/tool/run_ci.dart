import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    // '.',
    'bluetooth',
    'bluetooth_web',
    'bluetooth_bluez',
    'bluetooth_flutter_blue',
    'bluetooth_server',
    'bluetooth_server_flutter',
    'bluetooth_server_app',
    'bluetooth_test',
    'bluetooth_test_app',
  ]) {
    await packageRunCi(join('..', dir));
  }
}
