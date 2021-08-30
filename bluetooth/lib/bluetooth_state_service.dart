// State service
import 'dart:async';

abstract class BluetoothStateService {
  bool? get supportsEnable;

  Future enable(
      {@Deprecated('Do no use') int? requestCode, int? androidRequestCode});

  Future disable();
}
