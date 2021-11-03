import 'package:flutter/material.dart';
import 'package:flutter_wallet/add_to_wallet.dart';
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
  bool canAddPaymentPass = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async{
    canAddPaymentPass = await AddToWallet.canAddPaymentPass();
    setState(() {});
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
        body: Column(
          children: [
            Text("canAddPaymentPass: $canAddPaymentPass"),
            LayoutBuilder(builder: (context, constraints) => AddToWalletButton(onData: _onAppleDataReceived, onDone: _onDone, width: constraints.maxWidth, height: 100, onGooglePayWalletIdProvided: (String walletId) async => <String, dynamic>{} )),
          ],
        ),
      ),
    );
  }
}
