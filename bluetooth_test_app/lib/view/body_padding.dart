import 'package:flutter/material.dart';

class BodyHPadding extends StatelessWidget {
  final Widget? child;
  const BodyHPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}
