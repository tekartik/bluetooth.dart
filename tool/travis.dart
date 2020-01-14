import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  // Regular dart package
  for (var dir in ['bluetooth']) {
    shell = shell.pushd(dir);
    await shell.run('''

pub get
dart tool/travis.dart

    ''');
    shell = shell.popd();
  }

  // Flutter package
  for (var dir in [
    'bluetooth_flutter_blue',
    'bluetooth_flutter',
    'bluetooth_server',
    'bluetooth_server_app',
    'bluetooth_test',
    'bluetooth_test_app'
  ]) {
    shell = shell.pushd(dir);
    await shell.run('''

flutter packages get
dart tool/travis.dart

    ''');
    shell = shell.popd();
  }
}
