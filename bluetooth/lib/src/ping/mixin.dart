import 'package:tekartik_bluetooth/uuid.dart';

const int demoServicePingNumber = 0x0101;

final Uuid16 demoServicePingCharacteristicUuid16 = Uuid16.fromValue(
  demoServicePingNumber,
);
