import 'package:flutter/material.dart';

class PeripheralScreen extends StatefulWidget {
  const PeripheralScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PeripheralScreenState createState() => _PeripheralScreenState();
}

class _PeripheralScreenState extends State<PeripheralScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
    );
  }
}

Future<void> goToPeripheralScreen(BuildContext context) async {
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) {
    return const PeripheralScreen();
  }));
}
