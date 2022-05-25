import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_wallet/flutter_wallet.dart';
import 'package:flutter_wallet/pk_add_pass_button.dart';

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

  init() async {
    canAddPaymentPass = await FlutterWallet.canAddPaymentPass();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Column(
          children: [
            if (Platform.isIOS) ...[
              Text("canAddPaymentPass: $canAddPaymentPass"),
              LayoutBuilder(builder: (context, constraints) => PKAddPassButton(width: constraints.maxWidth, height: 100)),
            ] else ...[
              ElevatedButton(onPressed: () => _startGooglePay(), child: Text("Add to Google Pay"))
            ]
          ],
        ),
      ),
    );

  _startGooglePay() {
    FlutterWallet.initiateGooglePayCardFlow(displayName: "John Smith", phoneNumber: "+1111111111", onData: (walletId, deviceId) => GooglePayRequest("1234", "34234", GoogleUserAddress(city: "Atlanta", country: "US", postalCode: "30318", addressLine1: "222333 Peachtree Place", addressLine2: "", administrativeArea: "GA")));
  }
}
