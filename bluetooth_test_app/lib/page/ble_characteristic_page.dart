import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_test_app/page/screen_mixin.dart';
import 'package:tekartik_bluetooth_test_app/utils/app_utils.dart';
import 'package:tekartik_bluetooth_test_app/view/app_button.dart';
import 'package:tekartik_bluetooth_test_app/view/app_text_field.dart';
import 'package:tekartik_bluetooth_test_app/view/body_container.dart';
import 'package:tekartik_bluetooth_test_app/view/body_padding.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/hex_utils.dart';

/// Decode a BigInt from bytes in big-endian encoding.
BigInt decodeBigInt(List<int> bytes) {
  var result = BigInt.from(0);
  for (var i = 0; i < bytes.length; i++) {
    result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

var _byteMask = BigInt.from(0xff);

/// Encode a BigInt into bytes using big-endian encoding.
Uint8List encodeBigInt(BigInt number) {
  // Not handling negative numbers. Decide how you want to do that.
  var size = (number.bitLength + 7) >> 3;
  var result = Uint8List(size);
  for (var i = 0; i < size; i++) {
    result[size - i - 1] = (number & _byteMask).toInt();
    number = number >> 8;
  }
  return result;
}

class AppBleCharacteristic {
  final BluetoothDeviceConnection? connection;
  final BleBluetoothCharacteristic characteristic;

  AppBleCharacteristic(
      {required this.connection, required this.characteristic});
}

class _ValueState {
  dynamic exception;
  Uint8List? value;
}

class BleCharacteristicPage extends StatefulWidget {
  final AppBleCharacteristic? appBleCharacteristic;

  const BleCharacteristicPage({Key? key, this.appBleCharacteristic})
      : super(key: key);

  @override
  _BleCharacteristicPageState createState() => _BleCharacteristicPageState();
}

class _BleCharacteristicPageState extends State<BleCharacteristicPage>
    with AppScreenMixin {
  final valueSubject = BehaviorSubject<_ValueState?>();
  final notifyValueSubject = BehaviorSubject<_ValueState?>();
  TextEditingController? intController;
  TextEditingController? textController;
  TextEditingController? base64Controller;

  bool checkFlag(int flag) {
    return ((widget.appBleCharacteristic?.characteristic.properties ?? 0) &
            flag) !=
        0;
  }

  @override
  void dispose() {
    intController?.dispose();
    textController?.dispose();
    base64Controller?.dispose();
    valueSubject.close();
    notifyValueSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var connection = widget.appBleCharacteristic!.connection;
    var descriptors = widget.appBleCharacteristic?.characteristic.descriptors;
    var characteristic = widget.appBleCharacteristic?.characteristic;

    var canRead = ((characteristic?.properties ?? 0) & blePropertyRead) != 0;
    var canIndicate = checkFlag(blePropertyIndicate);
    var canWrite = ((characteristic?.properties ?? 0) & blePropertyWrite) != 0;
    var canNotify =
        ((characteristic?.properties ?? 0) & blePropertyNotify) != 0;

    var propertiesText = propertiesAsText(characteristic?.properties ?? 0);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Characteristic'),
        ),
        body: ListView(children: <Widget>[
          BodyContainer(
            child: Column(
              children: [
                ListTile(
                    title: const Text('Characteristic'),
                    subtitle: Text(uuidText(characteristic?.uuid))),
                ListTile(
                    title: const Text('Properties'),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(widget.appBleCharacteristic?.characteristic
                                  .properties
                                  .toRadixString(2) ??
                              'no properties'),
                          if (propertiesText.isNotEmpty) Text(propertiesText)
                        ])),
                if (descriptors?.isNotEmpty ?? false)
                  ...descriptors!.map((descriptor) {
                    return ListTile(
                        title: const Text('Descriptor'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(uuidText(descriptor.uuid,
                                parent: characteristic?.uuid))
                          ],
                        ));
                  }),
                if (canRead || canIndicate)
                  StreamBuilder<_ValueState?>(
                      initialData: valueSubject.valueOrNull,
                      stream: valueSubject,
                      builder: (context, snapshot) {
                        var state = snapshot.data;
                        var value = state?.value;
                        String? valuePretty;
                        BigInt? valueInt;
                        if (value != null) {
                          try {
                            valuePretty = hexPretty(value);
                          } catch (_) {}
                          try {
                            valueInt = decodeBigInt(value);
                          } catch (_) {}
                        }
                        return ListTile(
                            leading: AppButton(
                                text: 'Read',
                                onPressed: () {
                                  () async {
                                    try {
                                      var bcv = await connection!
                                          .readCharacteristic(widget
                                              .appBleCharacteristic!
                                              .characteristic);
                                      valueSubject.add(
                                          _ValueState()..value = bcv.value);
                                    } catch (e) {
                                      valueSubject
                                          .add(_ValueState()..exception = e);
                                    }
                                  }();
                                }),
                            subtitle: state == null
                                ? null
                                : ((state.exception != null)
                                    ? Text(state.exception.toString())
                                    : Text(value != null
                                        ? '$valuePretty\n$valueInt'
                                        : '[null]')));
                      }),
                if (canWrite) ...[
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: BodyHPadding(
                          child: AppTextField(
                            labelText: 'Hex data',
                            controller: base64Controller ??=
                                TextEditingController(),
                          ),
                        ),
                      ),
                      AppButton(
                          onPressed: () async {
                            try {
                              var data = parseHexString(base64Controller!.text);
                              var bcv = widget
                                  .appBleCharacteristic!.characteristic
                                  .withValue(asUint8List(data));
                              try {
                                await connection!.writeCharacteristic(bcv);
                                snackInfo(context, 'Write $bcv success');
                              } catch (e) {
                                snackError(context, 'Write $bcv error $e');
                              }
                            } catch (e) {
                              snackError(context, 'Cannot parse data');
                            }
                          },
                          text: 'Write')
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: BodyHPadding(
                          child: AppTextField(
                            labelText: 'int data',
                            controller: intController ??=
                                TextEditingController(),
                          ),
                        ),
                      ),
                      AppButton(onPressed: () {}, text: 'Write')
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                ],
                if (canNotify)
                  StreamBuilder<_ValueState?>(
                      initialData: notifyValueSubject.valueOrNull,
                      stream: valueSubject,
                      builder: (context, snapshot) {
                        var state = snapshot.data;
                        var value = state?.value;
                        String? valuePretty;
                        BigInt? valueInt;
                        if (value != null) {
                          try {
                            valuePretty = hexPretty(value);
                          } catch (_) {}
                          try {
                            valueInt = decodeBigInt(value);
                          } catch (_) {}
                        }
                        return Column(
                          children: [
                            ListTile(
                                title: Row(
                                  children: [
                                    AppButton(
                                        text: 'Register',
                                        onPressed: () {
                                          () async {
                                            try {
                                              var bcv = await connection!
                                                  .readCharacteristic(widget
                                                      .appBleCharacteristic!
                                                      .characteristic);
                                              valueSubject.add(_ValueState()
                                                ..value = bcv.value);
                                            } catch (e) {
                                              valueSubject.add(
                                                  _ValueState()..exception = e);
                                            }
                                          }();
                                        }),
                                    AppButton(
                                        text: 'Unregister',
                                        onPressed: () {
                                          () async {
                                            try {
                                              var bcv = await connection!
                                                  .readCharacteristic(widget
                                                      .appBleCharacteristic!
                                                      .characteristic);
                                              valueSubject.add(_ValueState()
                                                ..value = bcv.value);
                                            } catch (e) {
                                              valueSubject.add(
                                                  _ValueState()..exception = e);
                                            }
                                          }();
                                        }),
                                  ],
                                ),
                                subtitle: state == null
                                    ? null
                                    : ((state.exception != null)
                                        ? Text(state.exception.toString())
                                        : Text(value != null
                                            ? '$valuePretty\n$valueInt'
                                            : '[null]'))),
                          ],
                        );
                      }),
              ],
            ),
          ),
        ]));
  }
}
