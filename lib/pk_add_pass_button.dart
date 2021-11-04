import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wallet/flutter_wallet.dart';
import 'package:uuid/uuid.dart';

// Button that shows the "Add to Apple Wallet" logo and text. Only works on iOS.
class PKAddPassButton extends StatefulWidget {
  static const _viewType = 'PKAddPassButton';

  final double width;
  final double height;
  final Widget? unsupportedPlatformChild;
  final Function? onPressed; // called when the button is pressed.
  final String _id = Uuid().v4();

  PKAddPassButton({Key? key, required this.width, required this.height, this.unsupportedPlatformChild, this.onPressed}) : super(key: key);

  @override
  _PKAddPassButtonState createState() => _PKAddPassButtonState();
}

class _PKAddPassButtonState extends State<PKAddPassButton> {
  get uiKitCreationParams => {'width': widget.width, 'height': widget.height, 'key': widget._id};

  @override
  void initState() {
    super.initState();
    FlutterWallet().addHandler(widget._id, _onMethodCall);
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case "onApplePayButtonPressed":
        if (widget.onPressed != null) widget.onPressed!();
        break;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) => Container(width: widget.width, height: widget.height, child: platformWidget(context));

  Widget platformWidget(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: PKAddPassButton._viewType,
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
    FlutterWallet().removeHandler(widget._id);
    super.dispose();
  }
}
