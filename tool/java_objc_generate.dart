import 'dart:io';

import 'package:tekartik_build_utils/flutter/app/generate.dart';
import 'package:path/path.dart';

Future main() async {
  var dirName = join('example', 'java_objc_app');
  try {
    await Directory(dirName).delete(recursive: true);
  } catch (_) {}
  //expect(Directory(dirName).existsSync(), isFalse);
  await gitGenerate(
      dirName: dirName, appName: 'tekartik_test_menu_java_objc_app');
}
