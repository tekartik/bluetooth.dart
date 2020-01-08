import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''

flutter analyze --no-current-package .
dartfmt -n --set-exit-if-changed .
# flutter test
  ''');
}
