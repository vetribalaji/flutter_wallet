import Flutter
import PassKit
import UIKit

class PKAddPassButtonNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var channel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger, channel: FlutterMethodChannel) {
        self.messenger = messenger
        self.channel = channel
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return PKAddPassButtonNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args as! [String: Any],
            binaryMessenger: messenger,
            channel: channel)
    }
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

class PKAddPassButtonNativeView: NSObject, FlutterPlatformView, PKAddPaymentPassViewControllerDelegate {
    private var _view: UIView
    private var _pass: FlutterStandardTypedData
    private var _width: CGFloat
    private var _height: CGFloat
    private var _channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: [String: Any],
        binaryMessenger messenger: FlutterBinaryMessenger?,
        channel: FlutterMethodChannel
    ) {
        _view = UIView()
        _pass = args["pass"] as! FlutterStandardTypedData
        _width = args["width"] as? CGFloat ?? 140
        _height = args["height"] as? CGFloat ?? 30
        _channel = channel
        super.init()
        createAddPassButton()
    }

    func view() -> UIView {
        _view
    }

    func createAddPassButton() {
        let passButton = PKAddPassButton(addPassButtonStyle: PKAddPassButtonStyle.black)
        passButton.frame = CGRect(x: 0, y: 0, width: _width, height: _height)
        passButton.addTarget(self, action: #selector(passButtonAction), for: .touchUpInside)
        _view.addSubview(passButton)
    }

    @objc func passButtonAction() {
        guard let config = PKAddPaymentPassRequestConfiguration.init(encryptionScheme: PKEncryptionScheme.ECC_V2) else {
            print("PKAddPaymentPassRequestConfiguration is null")
            return
        }

        guard let controller = PKAddPaymentPassViewController(requestConfiguration: config, delegate: self) else {
            print("PKAddPaymentPassViewController is null")
            return
        }

        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            print("Root VC unavailable")
            return
        }

        rootVC.present(controller, animated: true)
        //_invokeAddButtonPressed()
    }

    func _invokeAddButtonPressed() {
        //_channel.invokeMethod(AddToWalletEvent.addButtonPressed.rawValue, arguments: [])
    }
}
