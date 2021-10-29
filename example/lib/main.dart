import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_wallet/add_to_wallet_button.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  Future<PKAddPaymentPassRequest> _onAppleDataReceived(List<String> certificates, String nonce, String nonceSignature) async {
    return PKAddPaymentPassRequest("", "", "");
  }

  _onDone(String? error) {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: LayoutBuilder(builder: (context, constraints) => AddToWalletButton(onData: _onAppleDataReceived, onDone: _onDone, width: constraints.maxWidth, height: 100)),
      ),
    );
  }
}
