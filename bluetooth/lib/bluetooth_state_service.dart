// State service
import 'dart:async';

abstract class BluetoothStateService {
  bool? get supportsEnable;

  Future enable(
      {@Deprecated('Use androidRequestCode') int? requestCode,
      int? androidRequestCode});

  Future disable();
}
