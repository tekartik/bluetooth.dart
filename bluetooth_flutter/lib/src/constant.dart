const String methodSetOptions = 'setOptions';
const String methodGetStatus = 'get_status';
const String methodEnable = 'enable';

const String namespace = 'com.tekartik.bluetooth_flutter';

const String paramLogLevel = 'logLevel';

/// No logs
final int bluetoothLogLevelNone = 0;

/// Log native verbose
final int bluetoothLogLevelVerbose = 2;

//
// model
//
const connectionIdKey = 'connectionId'; // int
const uuidKey = 'uuid'; // String
const characteristicsKey = 'characteristics'; // list
const propertiesKey = 'properties'; // int
const descriptorsKey = 'descriptors'; // int
const valueKey = 'value'; // Uint8List
const serviceUuidKey = 'service'; // uuid as string for readCharacteristic
const characteristicUuidKey =
    'characteristic'; // uuid as string for readCharacteristic
const statusKey = 'status'; // uuid as string for readCharacteristic

///Characteristic proprty: Characteristic is broadcastable.
const blePropertyBroadcast = 0x01;

/// Characteristic property: Characteristic is readable.
const blePropertyRead = 0x02;

/// Characteristic property: Characteristic can be written without response.
const blePropertyWriteNoResponse = 0x04;

/// Characteristic property: Characteristic can be written.
const blePropertyWrite = 0x08;

/// Characteristic property: Characteristic supports notification
const blePropertyNotify = 0x10;

/// Characteristic property: Characteristic supports indication
const blePropertyIndicate = 0x20;

/// Characteristic property: Characteristic supports write with signature
const blePropertySignedWrite = 0x40;

/// Characteristic property: Characteristic has extended properties
const blePropertyExtendedProps = 0x80;

/// A GATT operation completed successfully
const androidBleGattSuccess = 0;

/// GATT read operation is not permitted
const androidBleGattReadNotPermitted = 0x2;

/// GATT write operation is not permitted
const androidBleGattWriteNotPermitted = 0x3;

/// Insufficient authentication for a given operation
const androidBleGattInsufficientAuthentication = 0x5;

/// The given request is not supported
const androidBleGattRequestNotSupported = 0x6;

/// Insufficient encryption for a given operation
const androidBleGattInsufficientEncryption = 0xf;

/// A read or write operation was requested with an invalid offset
const androidBleGattInvalidOffset = 0x7;

/// A write operation exceeds the maximum length of the attribute
const androidBleGattInvalidAttributeLength = 0xd;

/// A remote device connection is congested.
const androidBleGattConnectionCongested = 0x8f;

/// A GATT operation failed, errors other than the above
const androidBleGattFailure = 0x101;

/// The profile is in disconnected state

const androidBleConnectionStateDisconnected = 0;

/// The profile is in connecting state

const androidBleConnectionStateConnecting = 1;

/// The profile is in connected state

const androidBleConnectionStateConnected = 2;

/// The profile is in disconnecting state

const androidBleConnectionStateDisconnecting = 3;

const bleDisconnectedTimeout = Duration(seconds: 5);
const bleReadCharacteristicTimeout = Duration(seconds: 5);
const bleConnectedTimeout = Duration(seconds: 30);
const bleDiscoverServicesTimeout = Duration(seconds: 30);
