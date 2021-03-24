/// Unique bluetooth identifier, typically an id representing an address
///
/// Use toString() to get a displayable text as device id
abstract class BluetoothDeviceId {
  String? get id;
}

abstract class BluetoothDeviceIdMixin implements BluetoothDeviceId {
  @override
  int get hashCode => id!.toLowerCase().hashCode;

  @override
  bool operator ==(other) =>
      other is BluetoothDeviceId &&
      id!.toLowerCase() == other.id!.toLowerCase();

  @override
  String toString() => id!;
}

class BluetoothDeviceIdImpl
    with BluetoothDeviceIdMixin
    implements BluetoothDeviceId {
  @override
  final String? id;
  const BluetoothDeviceIdImpl(this.id);
}
