import 'package:tekartik_bluetooth/uuid.dart';

const int batteryServiceNumber = 0x180f;
const int batteryServiceLevelNumber = 0x2a19;

final Uuid16 batteryServiceUuid16 = Uuid16.fromValue(batteryServiceNumber);
final Uuid16 batteryServiceLevelCharacteristicUuid16 =
    Uuid16.fromValue(batteryServiceLevelNumber);
Uuid128 batteryServiceBaseUuid128 =
    Uuid128('00000000-0000-1000-8000-00805f9b34fb');
Uuid128 batteryServiceUuid128 =
    batteryServiceBaseUuid128.withUuid16(batteryServiceUuid16);
final Uuid128 batteryServiceLevelCharacteristicUuid128 =
    batteryServiceUuid128.withUuid16(batteryServiceLevelCharacteristicUuid16);
