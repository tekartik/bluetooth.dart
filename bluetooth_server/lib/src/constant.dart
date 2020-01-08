import 'package:tekartik_common_utils/common_utils_import.dart';

// Get the server information
const methodGetServerInfo = 'bluetoothGetServerInfo';

// Generic method to forward to tekartik_bluetooth_flutter
const methodBluetooth = 'bluetooth';

const serverInfoName = 'tekartik_bluetooth_server';
final serverInfoVersion1 = Version(0, 0, 1);

// server version
final serverInfoVersion = serverInfoVersion1;

// Min version expected by the client
final serverInfoMinVersion = serverInfoVersion1;

const keyMethod = 'method';
const keyParam = 'param';

// server info
const keyName = 'name';
const keyVersion = 'version';
const keyIsIOS = 'isIOS';
const keyIsAndroid = 'isAndroid';

const bluetoothServerDefaultPort = 8502;
