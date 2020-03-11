const int enableBluetoothRequestCode = 1;

// {"id":....,"name"}
const prefsDeviceKey = 'device';

int batteryServiceNumber = 0x180F;
int batteryLevelCharacteristicNumber = 0x2A19;

// Demo help on finding the device
const String demoAdvertiseDataServiceUuid =
    '00000000-6cc6-43b3-b198-ac03cc44949e';
const String custom1AdvertiseDataServiceUuid =
    '0000F001-6cc6-43b3-b198-ac03cc44949e';
