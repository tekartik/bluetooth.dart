// State service
import 'dart:async';

abstract class BluetoothStateService {
  bool? get supportsEnable;

  Future enable({@deprecated int? requestCode, int? androidRequestCode});

  Future disable();
}
