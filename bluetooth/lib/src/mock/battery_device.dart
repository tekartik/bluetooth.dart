import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/src/battery.dart';
import 'package:tekartik_bluetooth/src/ping/mixin.dart';
import 'package:tekartik_bluetooth/src/rx_utils.dart';
import 'package:tekartik_bluetooth/utils/byte_utils.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

const int batteryServiceNumber = 0xF011;
const int batteryServiceVersionNumber = 0x0001;
final Uuid128 batteryServiceVersionCharacteristicUuid128 = demoServiceUuid128
    .withUuid16(batteryServiceVersionCharacteristicUuid16);

// Demo service - generated
final Uuid128 demoServiceUuid128 = Uuid128(
  '0000${uint16GetString(batteryServiceNumber)}-87ae-41fe-b826-6ad4069efaff',
);
final Uuid16 batteryServiceVersionCharacteristicUuid16 = Uuid16.fromValue(
  batteryServiceVersionNumber,
);
// final Uuid16 _invalidServiceUuid16 = Uuid16('ffff');
final Uuid32 androidDemoDevicesManagerUuid32 = Uuid32('ffffffff');

final Uuid128 demoServicePingCharacteristicUuid128 = demoServiceUuid128
    .withUuid16(demoServicePingCharacteristicUuid16);

class BatteryRemoteDevice {
  BluetoothPeripheral? bluetoothPeripheral;

  static const namePrefix = 'MockRemote ';

  // publish here we don't replay like behavior
  final _writeCharacteristicEvent =
      PublishSubjectWrapper<BluetoothPeripheralWriteCharacteristicEvent>();

  SubjectInterface<BluetoothPeripheralWriteCharacteristicEvent>
  get writeCharacteristicEvent => _writeCharacteristicEvent;

  /// Where to post notification to be sent
  final _bleNotificationWrapper =
      PublishSubjectWrapper<BleBluetoothCharacteristicValue>();

  SubjectInterface<BleBluetoothCharacteristicValue> get bleNotification =>
      _bleNotificationWrapper;

  BatteryRemoteDevice({this.bluetoothPeripheral});

  static final String deviceIdKey = 'peripheralDeviceId';
  static final String batteryKey = 'peripheralBattery'; // int

  bool hasCharacteristic(Uuid128 uuid) {
    for (var service in gattServices) {
      for (var bs in service.characteristics) {
        if (bs.uuid == uuid) {
          return true;
        }
      }
    }
    return false;
  }

  List<BluetoothGattService> gattServices = <BluetoothGattService>[
    BluetoothGattService(
      uuid: demoServiceUuid128,
      characteristics: <BluetoothGattCharacteristic>[
        BluetoothGattCharacteristic(
          uuid: batteryServiceVersionCharacteristicUuid128,
          properties: BluetoothGattCharacteristic.propertyRead,
          permissions: BluetoothGattCharacteristic.permissionRead,
          description: 'Version',
        ),
        BluetoothGattCharacteristic(
          uuid: demoServiceUuid128.withUuid16(
            demoServicePingCharacteristicUuid16,
          ),
          properties: BluetoothGattCharacteristic.propertyWrite,
          permissions: BluetoothGattCharacteristic.permissionWrite,
          description: 'Ping',
        ),
      ],
    ),
    BluetoothGattService(
      uuid: batteryServiceUuid128,
      characteristics: <BluetoothGattCharacteristic>[
        BluetoothGattCharacteristic(
          uuid: batteryServiceLevelCharacteristicUuid128,
          properties:
              BluetoothGattCharacteristic.propertyNotify |
              BluetoothGattCharacteristic.propertyRead,
          permissions: BluetoothGattCharacteristic.permissionRead,
          description: 'Battery level',
        ),
      ],
    ),
  ];

  Future setCharacteristicValue(BleBluetoothCharacteristicValue bcv) async {
    await bluetoothPeripheral!.setCharacteristicValue(
      serviceUuid: bcv.service.uuid,
      characteristicUuid: bcv.uuid,
      value: bcv.value,
    );
  }

  Future setAndNotifyCharacteristicValue(
    BleBluetoothCharacteristicValue bcv,
  ) async {
    await setCharacteristicValue(bcv);
    bleNotification.sink.add(bcv);
  }

  Future notifyCharacteristicValue(BleBluetoothCharacteristicValue bcv) async {
    await bluetoothPeripheral!.notifyCharacteristicValue(
      serviceUuid: bcv.service.uuid,
      characteristicUuid: bcv.uuid,
    );
  }

  Future<BleBluetoothCharacteristicValue?> getCharacteristicValue(
    BleBluetoothCharacteristic bc,
  ) async {
    var value = await bluetoothPeripheral!.getCharacteristicValue(
      serviceUuid: bc.service.uuid,
      characteristicUuid: bc.uuid,
    );
    return BleBluetoothCharacteristicValue(bc: bc, value: value);
  }

  Future start() async {
    var advertiseData = AdvertiseData(
      services: [
        // We show 2 services
        // AdvertiseDataService(uuid: discoverableServiceUuid),
        // AdvertiseDataService(uuid: deviceSpecificDiscoverableServiceUuid)
      ],
    );
    await bluetoothPeripheral!.startAdvertising(advertiseData: advertiseData);
  }

  Future stop() async {
    await bluetoothPeripheral!.stopAdvertising();
  }

  final _batterySubject = BehaviorSubject<num>();

  Stream<num> get batteryStream => _batterySubject.distinct();

  StreamSink<num> get batterySink => _batterySubject;
}
