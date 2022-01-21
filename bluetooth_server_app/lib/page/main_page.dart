// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth_server/src/constant.dart';
import 'package:tekartik_bluetooth_server_app/src/app.dart';
import 'package:tekartik_bluetooth_server_app/src/prefs.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

class BluetoothServerHomePage extends StatefulWidget {
  const BluetoothServerHomePage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _BluetoothServerHomePageState createState() =>
      _BluetoothServerHomePageState();
}

class _BluetoothServerHomePageState extends State<BluetoothServerHomePage> {
  bool _startPending = false;
  int? port = bluetoothServerDefaultPort;

// Create a text controller. We will use it to retrieve the current value
  // of the TextField!
  final portInputController = TextEditingController();

  final List<String> logs = [];

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    portInputController.dispose();
    super.dispose();
  }

  void log(String message) {
    // ignore: avoid_print
    print(message);
    setState(() {
      logs.add(message);
      if (logs.length > 200) {
        var sublist = logs.sublist(50);
        logs
          ..clear()
          ..addAll(sublist);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title!),
        ),
        body: FutureBuilder(
            future: _loadPrefs(),
            builder: (BuildContext context, AsyncSnapshot<Prefs?> snapshot) {
              if (snapshot.data == null) {
                return Container();
              } else {
                var widgets = <Widget>[
                  Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        app.bluetoothServerStarted
                            ? 'Bluetooth server listening on ${app.bluetoothServer!.port}'
                            : (_startPending
                                ? 'Starting listening on $port'
                                : 'Press START to start Bluetooth server'),
                      )),
                  Container(
                      width: 240.0,
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: portInputController,
                        decoration: const InputDecoration(
                            labelText: 'Port number (0 for any)'),
                        keyboardType: TextInputType.number,
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          if (!app.bluetoothServerStarted) {
                            await startServer();
                          } else {
                            await stopServer();
                          }
                        },
                        child:
                            Text(app.bluetoothServerStarted ? 'STOP' : 'START'),
                      ),
                    ],
                  )
                ];
                /*
            if (openError != null) {
              widgets.add(Text(openError));
            }
            */
                if (app.prefs!.showConsole) {
                  widgets.add(Expanded(
                      child: ListView.builder(
                          reverse: true,
                          itemCount: logs.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: Text(
                                  logs[logs.length - index - 1],
                                  style: const TextStyle(fontSize: 10.0),
                                ));
                          })));
                }
                widgets.add(const SizedBox(
                  height: 8.0,
                ));
                startApp();
                return Center(
                  // Center is a layout widget. It takes a single child and positions it
                  // in the middle of the parent.
                  child: Column(
                    // Column is also layout widget. It takes a list of children and
                    // arranges them vertically. By default, it sizes itself to fit its
                    // children horizontally, and tries to be as tall as its parent.
                    //
                    // Invoke 'debug paint' (press 'p' in the console where you ran
                    // 'flutter run', or select 'Toggle Debug Paint' from the Flutter tool
                    // window in IntelliJ) to see the wireframe for each widget.
                    //
                    // Column has various properties to control how it sizes itself and
                    // how it positions its children. Here we use mainAxisAlignment to
                    // center the children vertically; the main axis here is the vertical
                    // axis because Columns are vertical (the cross axis would be
                    // horizontal).
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widgets,
                  ),
                );
              }
            })

        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }

  Future stopServer() async {
    await app.prefs!.setAutoStart(false);
    setState(() {
      _startPending = true;
    });
    await app.stopServer();
    setState(() {
      _startPending = false;
    });
    log('Server stopped');
  }

  Future startApp() async {
    if (!app.started) {
      app.started = true;
      await Future<dynamic>.delayed(const Duration());
      //devPrint('startApp');
      portInputController.text = (app.prefs!.port ?? 0).toString();
      if (app.prefs!.autoStart) {
        await startServer();
      }
    }
  }

  Future startServer() async {
    port = parseInt(portInputController.text) ?? 0;
    setState(() {
      _startPending = true;
    });
    try {
      var server = await app.startServer(port,
          notifyCallback: (bool response, String method, dynamic param) {
        if (response == false) {
          if (method == methodBluetooth) {
            var paramsMap = param as Map;
            var bluetoothMethod = paramsMap['method'] as String?;
            dynamic bluetoothParam = paramsMap['param'];
            log('method $bluetoothMethod param $bluetoothParam');
            /*
            if (sqfliteMethod == methodOpenDatabase) {
              log('open ${(sqfliteParam as Map)['path']}');
            } else if (sqfliteMethod == methodBatch) {
              var operations = (sqfliteParam as Map)['operations'] as List;
              for (var operation in operations) {
                var operationMap = operation as Map;
                _logOperation(operationMap);
              }
            } else {
              var _methodParam = sqfliteParam as Map;
              if (_methodParam != null) {
                _logOperation(_methodParam);
              }
            }
             */
          }
        }
        // print('$response $method $param');
        // log('$response $method $param');
      });
      // Save port in prefs upon success
      await app.prefs!.setPort(port);
      await app.prefs!.setAutoStart(true);
      var serverPort = server.port;
      logs.clear();
      log('Version: ${app.version}');
      log('Listening on port $serverPort');
      log('WebSocket url: ${app.bluetoothServer!.url}');
      if (Platform.isAndroid) {
        log('Make sure you have ran at least once: adb forward tcp:$serverPort tcp:$serverPort');
      }
    } catch (e, st) {
      setState(() {
        log(e.toString());
      });
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(st);
    }
    setState(() {
      _startPending = false;
    });
  }

  Future<Prefs?> _loadPrefs() async {
    //devPrint('prefs: ${app.prefs?.toString()}');
    if (app.prefs == null) {
      var prefs = Prefs();
      await prefs.load();
      port = prefs.port;
      portInputController.text = port.toString();
      app.prefs = prefs;
      //devPrint('loaded prefs: ${app.prefs?.toString()}');
    }
    return app.prefs;
  }
}
