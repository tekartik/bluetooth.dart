// State service
import 'dart:async';

abstract class BluetoothStateService {
  bool? get supportsEnable;

  Future enable({
    @Deprecated('Use androidRequestCode') int? requestCode,
    int? androidRequestCode,
  });

  /// No longer working on Android SDK33
  Future disable();
}
