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

const int lumiServiceNumber = 0xF011;
const int lumiServiceVersionNumber = 0x0001;
final Uuid128 lumiServiceVersionCharacteristicUuid128 =
    lumiServiceUuid128.withUuid16(lumiServiceVersionCharacteristicUuid16);

// Lumi service - generated
final Uuid128 lumiServiceUuid128 = Uuid128(
    '0000${uint16GetString(lumiServiceNumber)}-87ae-41fe-b826-6ad4069efaff');
final Uuid16 lumiServiceVersionCharacteristicUuid16 =
    Uuid16.fromValue(lumiServiceVersionNumber);
// final Uuid16 _invalidServiceUuid16 = Uuid16('ffff');
final Uuid32 androidLumiDevicesManagerUuid32 = Uuid32('ffffffff');

final Uuid128 lumiServicePingCharacteristicUuid128 =
    lumiServiceUuid128.withUuid16(lumiServicePingCharacteristicUuid16);

class BatteryRemoteDevice {
  BluetoothPeripheral bluetoothPeripheral;

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

  static final String deviceIdKey = 'lumiPeripheralDeviceId';
  static final String batteryKey = 'lumiPeripheralBattery'; // int

  /*
  String initId(Prefs prefs) {
    var deviceIdText = prefs?.getString(LumiPeripheral.deviceIdKey);
    if (deviceIdText == null) {
      var sb = StringBuffer();
      for (int i = 0; i < 4; i++) {
        sb.write(Random().nextInt(10).toString());
      }
      deviceIdText = sb.toString();
      prefs?.setString(LumiPeripheral.deviceIdKey, deviceIdText);
    }
    return deviceIdText;
  }
  */
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
        uuid: lumiServiceUuid128,
        characteristics: <BluetoothGattCharacteristic>[
          BluetoothGattCharacteristic(
              uuid: lumiServiceVersionCharacteristicUuid128,
              properties: BluetoothGattCharacteristic.propertyRead,
              permissions: BluetoothGattCharacteristic.permissionRead,
              description: 'Version'),
          BluetoothGattCharacteristic(
              uuid: lumiServiceUuid128
                  .withUuid16(lumiServicePingCharacteristicUuid16),
              properties: BluetoothGattCharacteristic.propertyWrite,
              permissions: BluetoothGattCharacteristic.permissionWrite,
              description: 'Ping'),
        ]),
    BluetoothGattService(
        uuid: batteryServiceUuid128,
        characteristics: <BluetoothGattCharacteristic>[
          BluetoothGattCharacteristic(
              uuid: batteryServiceLevelCharacteristicUuid128,
              properties: BluetoothGattCharacteristic.propertyNotify |
                  BluetoothGattCharacteristic.propertyRead,
              permissions: BluetoothGattCharacteristic.permissionRead,
              description: 'Battery level')
        ])
  ];

  /*
  Future init(Prefs prefs) async {
    /// An id is generate and saved in prefs
    var deviceIdText = initId(prefs);

    BluetoothPeripheral bluetoothPeripheral;
    if ((await getDeviceInfo()).isPhysicalDevice) {
      try {
        bluetoothPeripheral = await BluetoothFlutter.initPeripheral(
            services: gattServices,
            deviceName: "${LumiPeripheral.namePrefix}${deviceIdText}");
      } catch (e) {
        print(e);
      }
    }
    this.bluetoothPeripheral = bluetoothPeripheral;

    // Init listeners
    initListeners();

    // Handle battery
    unawaited(() async {
      await for (var battery in batteryStream) {
        await setAndNotifyCharacteristicValue(
            bleBatteryServiceLevelCharacteristic.withValue(
                BleBatteryServiceLevel(value: battery.round()).data));
      }
    }());

    if (bluetoothPeripheral != null) {
      // Handle peripheral write
      unawaited(() async {
        await for (var writeEvent
            in bluetoothPeripheral.onWriteCharacteristic()) {
          writeCharacteristicEvent.sink.add(writeEvent);
        }
      }());
    }

    await initValues(prefs);
  }

  // Init listeners
  void initListeners() {
    // handle writes
    unawaited(() async {
      await for (var writeEvent in writeCharacteristicEvent.stream) {
        unawaited(() async {
          // Lumi service?
          if (writeEvent.serviceUuid == lumiServiceUuid128) {
            // Ping
            var characteristicNumber =
                writeEvent.characteristicUuid.shortNumberUuid16.value;
            switch (characteristicNumber) {
              case lumiServicePingNumber:
                {
                  // We response right await to a ping event
                  await setAndNotifyCharacteristicValue(
                      bleLumiServiceLastActionResultCharacteristic.withValue(
                          BleLumiServiceLastActionResult(
                                  actionId: characteristicNumber,
                                  result: lumiServiceResultNoError)
                              .data));
                  break;
                }
              case lumiServiceStandbyDurationNumber:
                {
                  if (hasCharacteristic(
                      lumiServiceStandbyDurationCharacteristicUuid128)) {
                    /*
                    // We response right await to a ping event
                    await setAndNotifyCharacteristicValue(
                        bleLumiServiceLastActionResultCharacteristic.withValue(
                            BleLumiServiceLastActionResult(
                                    actionId: characteristicNumber,
                                    result: lumiServiceResultNoError)
                                .data));

                     */
                    // No response in 0.4.0
                    print('received stand by duration: ${writeEvent}');
                  }
                  break;
                }
              case lumiServiceMeasureStartNumber:
                {
                  // Check whether we are already measuring
                  var state = await getState();
                  //TODO handle when calibrating or other state (battery, not ready...)
                  if (state.measuring) {
                    // Already measuring
                    await setAndNotifyCharacteristicValue(
                        bleLumiServiceLastActionResultCharacteristic.withValue(
                            BleLumiServiceLastActionResult(
                                    actionId: characteristicNumber,
                                    result: lumiServiceResultInvalidStateError)
                                .data));
                    return;
                  }

                  // Clear the measurement value and notify
                  await setAndNotifyCharacteristicValue(
                      bleLumiServiceMeasurementValueCharacteristic
                          .withValue(null));

                  // Send and notify the state
                  await updateState(measuring: true);

                  var param =
                      BleLumiServiceMeasurementStart.fromData(writeEvent.value);

                  // Send the response
                  await setAndNotifyCharacteristicValue(
                      bleLumiServiceLastActionResultCharacteristic.withValue(
                          BleLumiServiceLastActionResult(
                                  actionId: characteristicNumber,
                                  result: lumiServiceResultNoError)
                              .data));

                  await sleep(param.step1Duration);
                  if (!(await getState()).measuring) {
                    print('measurement cancelled');
                    break;
                  }
                  //devPrint('--1');
                  // await sleep(param.step2Duration);
                  // await Future.delayed(Duration(milliseconds: step2Duration));
                  await sleep(param.step2Duration);
                  if (!(await getState()).measuring) {
                    print('measurement cancelled');
                    break;
                  }
                  //devPrint('--2');

                  // Send the measurement value first
                  var measurementValue = BleLumiServiceMeasurementValue(
                          value: 123456000 + Random().nextInt(1000))
                      .data;
                  // Set and notify
                  await setAndNotifyCharacteristicValue(
                      bleLumiServiceMeasurementValueCharacteristic
                          .withValue(measurementValue));

                  // Send the state
                  await updateState(measuring: false);

                  break;
                }
              case lumiServiceMeasureStopNumber:
                {
                  // Check whether we are already measuring
                  var state = await getState();
                  if (!state.measuring) {
                    // Already measuring
                    await setAndNotifyCharacteristicValue(
                        bleLumiServiceLastActionResultCharacteristic.withValue(
                            BleLumiServiceLastActionResult(
                                    actionId: characteristicNumber,
                                    result: lumiServiceResultInvalidStateError)
                                .data));
                    return;
                  }

                  // Clear the measurement value and notify
                  await setAndNotifyCharacteristicValue(
                      bleLumiServiceMeasurementValueCharacteristic
                          .withValue(null));

                  // Send and notify the state
                  await updateState(measuring: false);

                  // Send the response
                  await setAndNotifyCharacteristicValue(
                      bleLumiServiceLastActionResultCharacteristic.withValue(
                          BleLumiServiceLastActionResult(
                                  actionId: characteristicNumber,
                                  result: lumiServiceResultNoError)
                              .data));
                  break;
                }
            }
          }
        }());
      }
    }());
  }
  
   */

  Future setCharacteristicValue(BleBluetoothCharacteristicValue bcv) async {
    await bluetoothPeripheral.setCharacteristicValue(
        serviceUuid: bcv.service.uuid,
        characteristicUuid: bcv.uuid,
        value: bcv.value);
  }

  Future setAndNotifyCharacteristicValue(
      BleBluetoothCharacteristicValue bcv) async {
    await setCharacteristicValue(bcv);
    bleNotification.sink.add(bcv);
  }

  Future notifyCharacteristicValue(BleBluetoothCharacteristicValue bcv) async {
    await bluetoothPeripheral.notifyCharacteristicValue(
      serviceUuid: bcv.service.uuid,
      characteristicUuid: bcv.uuid,
    );
  }

  Future<BleBluetoothCharacteristicValue> getCharacteristicValue(
      BleBluetoothCharacteristic bc) async {
    var value = await bluetoothPeripheral.getCharacteristicValue(
        serviceUuid: bc.service.uuid, characteristicUuid: bc.uuid);
    return BleBluetoothCharacteristicValue(bc: bc, value: value);
  }

  /*
  Future initValues(Prefs prefs) async {
    // Initialize some battery value
    int battery =
        prefs?.getInt(LumiPeripheral.batteryKey) ?? 50; // quick test with 50
    batterySink.add(battery);

    powerStateSink.add(PowerState.off);
    coverStateSink.add(CoverState.closed);
    tubeStateSink.add(TubeState.notPresent);

    // Default value
    // From prefs?
    int version = 1;

    // Version
    await setCharacteristicValue(BleBluetoothCharacteristicValue(
        service: bleLumiService,
        uuid: lumiServiceVersionCharacteristicUuid128,
        value: BleLumiServiceVersion(version: version).data));

    // State

    // Send notification
    unawaited(() async {
      await for (var bleNotification in bleNotification.stream) {
        await notifyCharacteristicValue(bleNotification);
      }
    }());
    /*
    unawaited(() async {
      // Handle UI changed
      await for (var state in _inStateSubject.stream) {
        var bcv = BleBluetoothCharacteristicValue(
            service: bleLumiService,
            uuid: lumiServiceStateCharacteristicUuid128,
            value: state.data);

        if (notifyState) {
          await setAndNotifyCharacteristicValue(bcv);
        } else {
          await setCharacteristicValue(bcv);
        }
      }
    }());

    // Handle client changes
    unawaited(() async {
      await for (var state in _inStateSubject.stream) {
        var bcv = BleBluetoothCharacteristicValue(
            service: bleLumiService,
            uuid: lumiServiceStateCharacteristicUuid128,
            value: state.data);
        if (notifyState) {
          await setAndNotifyCharacteristicValue(bcv);
        } else {
          await setCharacteristicValue(bcv);
        }
      }
    }());
    */

    void checkCalibration() {
      if (needCalibrationStateSubject.value ==
              NeedCalibrationState.needCalibration &&
          calibratingStateSubject.value != CalibratingState.calibrating &&
          _tubeStateSubject.value != TubeState.present &&
          _coverStateSubject.value != CoverState.opened) {
        () async {
          await updateState(calibrating: true);
          await sleep(2000);
          needCalibrationStateSubject
              .add(NeedCalibrationState.notNeedCalibration);
          await updateState(calibrating: false);
        }();
      }
    }

    // From UI
    unawaited(() async {
      await for (var tubeState in tubeStateStream) {
        // Changed?
        bool tubePresent = tubeState == TubeState.present;
        await updateState(tubePresent: tubePresent);
        checkCalibration();
      }
    }());

    unawaited(() async {
      await for (var coverState in coverStateStream) {
        // Changed?
        bool coverOpened = coverState == CoverState.opened;
        await updateState(coverOpened: coverOpened);
        checkCalibration();
      }
    }());

    unawaited(() async {
      await for (var needCalibrationState
          in needCalibrationStateSubject.distinct()) {
        // Changed?
        bool needCalibration =
            needCalibrationState == NeedCalibrationState.needCalibration;
        await updateState(needCalibration: needCalibration);
        checkCalibration();
      }
    }());

    // initial state
    await updateState();
  }

  //TODO call it?
  void dispose() {
    //_state.close();
    unawaited(_stateSubject.close());
  }

  // Prefs?
  bool notifyBattery = true;
  bool notifyState = true;
  */
  Future start() async {
    var advertiseData = AdvertiseData(services: [
      // We show 2 services
      // AdvertiseDataService(uuid: discoverableServiceUuid),
      // AdvertiseDataService(uuid: deviceSpecificDiscoverableServiceUuid)
    ]);
    await bluetoothPeripheral.startAdvertising(advertiseData: advertiseData);
  }

  Future stop() async {
    await bluetoothPeripheral.stopAdvertising();
  }

  /*
  final _powerStateSubject = BehaviorSubject<PowerState>();

  Stream<PowerState> get powerStateStream => _powerStateSubject.distinct();

  StreamSink<PowerState> get powerStateSink => _powerStateSubject;

  final _tubeStateSubject = BehaviorSubject<TubeState>();

  Stream<TubeState> get tubeStateStream => _tubeStateSubject.distinct();

  StreamSink<TubeState> get tubeStateSink => _tubeStateSubject;

  final _coverStateSubject = BehaviorSubject<CoverState>();

  Stream<CoverState> get coverStateStream => _coverStateSubject.distinct();

  StreamSink<CoverState> get coverStateSink => _coverStateSubject;
  */
  final _batterySubject = BehaviorSubject<num>();

  Stream<num> get batteryStream => _batterySubject.distinct();

  StreamSink<num> get batterySink => _batterySubject;
/*
  final calibratingStateSubject = BehaviorSubject<CalibratingState>();
  final needCalibrationStateSubject =
      BehaviorSubject<NeedCalibrationState>.seeded(
          NeedCalibrationState.notNeedCalibration);
          
   */
}
