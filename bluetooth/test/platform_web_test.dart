@TestOn('browser')
library;

import 'package:tekartik_bluetooth/bluetooth_mock.dart';
import 'package:test/test.dart';

/// Run with `dart test -p chrome -c dart2js,dart2wasm test/platform_web_test.dart`.
void main() {
  test('mock platform on the web (js and wasm)', () {
    var manager = BluetoothManagerMock(peripheral: null);
    // Used to throw on wasm (Platform._operatingSystem).
    expect(manager.isAndroid, isFalse);
    expect(manager.isIOS, isFalse);
    expect(BluetoothAdminManagerMock().isAndroid, isFalse);
  });
}
