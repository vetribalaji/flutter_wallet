import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wallet/add_to_wallet.dart';
import 'package:uuid/uuid.dart';

class PKAddPaymentPassRequest {
  final String encryptedPassData;
  final String activationData;
  final String ephemeralPublicKey;

  const PKAddPaymentPassRequest(this.encryptedPassData, this.activationData, this.ephemeralPublicKey);
}

class AddToWalletButton extends StatefulWidget {
  static const viewType = 'PKAddPassButton';

  final double width;
  final double height;
  final Widget? unsupportedPlatformChild;
  final FutureOr<PKAddPaymentPassRequest> Function(List<String> certificates, String nonce, String nonceSignature) onData;
  final Function(String? error) onDone;
  final String _id = Uuid().v4();

  AddToWalletButton(
      {Key? key,
        required this.width,
        required this.height,
        required this.onData,
        required this.onDone,
        this.unsupportedPlatformChild, })
      : super(key: key);

  @override
  _AddToWalletButtonState createState() => _AddToWalletButtonState();
}

class _AddToWalletButtonState extends State<AddToWalletButton> {
  get uiKitCreationParams => {
    'width': widget.width,
    'height': widget.height,
    'key': widget._id,
  };

  @override
  void initState() {
    super.initState();
    AddToWallet().addHandler(widget._id, _onMethodCall);
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case "onApplePayDataReceived":
        final List<String> certificates = call.arguments["certificates"];
        final String nonce = call.arguments["nonce"];
        final String nonceSignature = call.arguments["nonceSignature"];

        final response = await widget.onData(certificates, nonce, nonceSignature);
        return {"activationData": response.activationData, "encryptedPassData": response.encryptedPassData, "ephemeralPublicKey": response.ephemeralPublicKey};
      case "onApplePayFinished":
        widget.onDone(call.arguments == null ? null : call.arguments as String);
        break;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: platformWidget(context),
    );
  }

  Widget platformWidget(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: AddToWalletButton.viewType,
          layoutDirection: Directionality.of(context),
          creationParams: uiKitCreationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      default:
        if (widget.unsupportedPlatformChild == null) throw UnsupportedError('Unsupported platform view');
        return widget.unsupportedPlatformChild!;
    }
  }

  @override
  void dispose() {
    AddToWallet().removeHandler(widget._id);
    super.dispose();
  }
}
