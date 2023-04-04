import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';
import 'package:tekartik_bluetooth_test_app/import/import_bluetooth.dart';
import 'package:tekartik_bluetooth_test_app/page/screen_mixin.dart';
import 'package:tekartik_bluetooth_test_app/utils/app_utils.dart';
import 'package:tekartik_bluetooth_test_app/view/app_button.dart';
import 'package:tekartik_bluetooth_test_app/view/app_text_field.dart';
import 'package:tekartik_bluetooth_test_app/view/body_container.dart';
import 'package:tekartik_bluetooth_test_app/view/body_padding.dart';

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

class _NotifyState {
  dynamic exception;
  List<Uint8List>? values;

  @override
  String toString() =>
      values == null ? 'error $exception' : 'values ${values!.length}';
}

class BleCharacteristicPage extends StatefulWidget {
  final AppBleCharacteristic? appBleCharacteristic;

  const BleCharacteristicPage({Key? key, this.appBleCharacteristic})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _BleCharacteristicPageState createState() => _BleCharacteristicPageState();
}

class _BleCharacteristicPageState extends State<BleCharacteristicPage>
    with AppScreenMixin {
  final valueSubject = BehaviorSubject<_ValueState?>();
  final notifyValueSubject = BehaviorSubject<_NotifyState?>();
  TextEditingController? intController;
  TextEditingController? textController;
  TextEditingController? base64Controller;

  StreamSubscription? notifySubscription;
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
    notifySubscription?.cancel();
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
                if (canRead)
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
                if (canIndicate || canNotify)
                  ListTile(
                      leading: AppButton(
                          text: 'Subscribe',
                          onPressed: () {
                            () async {
                              try {
                                var characteristic =
                                    widget.appBleCharacteristic!.characteristic;
                                notifySubscription?.cancel().unawait();

                                notifySubscription = connection!
                                    .onCharacteristicValueChanged(
                                        characteristic)
                                    .listen((event) {
                                  // ignore: avoid_print
                                  print('received: $event ${event.value}');
                                  var list =
                                      notifyValueSubject.valueOrNull?.values ??
                                          <Uint8List>[];
                                  list.insert(0, event.value);
                                  if (list.length > 100) {
                                    list = list.sublist(0, 100);
                                  }
                                  notifyValueSubject
                                      .add(_NotifyState()..values = list);
                                });
                                await connection.registerCharacteristic(
                                    characteristic, true);
                                // print('onCharacteristicValueChanged');
                              } catch (e) {
                                // ignore: avoid_print
                                print('error $e registerCharacteristic');
                              }
                            }();
                          })),
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
                                // ignore: use_build_context_synchronously
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
                if (canIndicate || canNotify)
                  StreamBuilder<_NotifyState?>(
                      initialData: notifyValueSubject.valueOrNull,
                      stream: notifyValueSubject,
                      builder: (context, snapshot) {
                        var state = snapshot.data;
                        var values = state?.values;
                        if (state == null) {
                          return Container();
                        }
                        if (state.exception != null) {
                          return ListTile(
                              title: const Text('Error'),
                              subtitle: Text(state.exception.toString()));
                        }
                        var list = values ?? <Uint8List>[];
                        return Column(
                            children: list.map((value) {
                          String? valuePretty;
                          BigInt? valueInt;
                          try {
                            valuePretty = hexPretty(value);
                          } catch (_) {}
                          try {
                            valueInt = decodeBigInt(value);
                          } catch (_) {}
                          return ListTile(
                              title: Text('$valuePretty'),
                              subtitle: valueInt == null
                                  ? null
                                  : Text(valueInt.toString()));
                        }).toList());
                      }),
              ],
            ),
          ),
        ]));
  }
}
