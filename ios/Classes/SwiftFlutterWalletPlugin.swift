import Flutter
import UIKit
import PassKit

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
    private var _key: String
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
        _key = args["key"] as! String
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
        NSLog("Creating PKPassButton...")

        let passButton = PKAddPassButton(addPassButtonStyle: PKAddPassButtonStyle.black)
        passButton.frame = CGRect(x: 0, y: 0, width: _width, height: _height)
        passButton.addTarget(self, action: #selector(passButtonAction), for: .touchUpInside)
        _view.addSubview(passButton)
    }

    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, generateRequestWithCertificateChain certificates: [Data], nonce: Data, nonceSignature: Data, completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void) {
        let map: [String: Any?] = ["certificates": certificates, "nonce": nonce, "nonceSignature": nonceSignature]
        _channel.invokeMethod("onApplePayDataReceived", arguments: map, result: { result in
            let paymentPassRequest = PKAddPaymentPassRequest.init()
            guard let resultMap = result as? [String: String?] else {
                return
            }
            paymentPassRequest.encryptedPassData = resultMap["encryptedPassData"]??.data(using: String.Encoding.utf8)
            paymentPassRequest.activationData = resultMap["activationData"]??.data(using: String.Encoding.utf8)
            paymentPassRequest.ephemeralPublicKey = resultMap["ephemeralPublicKey"]??.data(using: String.Encoding.utf8)
            handler(paymentPassRequest)
        })
    }

    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, didFinishAdding pass: PKPaymentPass?, error: Error?) {
        _channel.invokeMethod("onApplePayFinished", arguments: error?.localizedDescription)
    }

    @objc func passButtonAction() {
        NSLog("PKPassButton pushed.")

        if (!PKAddPaymentPassViewController.canAddPaymentPass()) {
            NSLog("PKAddPaymentPassViewController canAddPaymentPass returned false")
            return
        }
        
        var config: PKAddPaymentPassRequestConfiguration?
        if #available(iOS 10.0, *) {
            config = PKAddPaymentPassRequestConfiguration.init(encryptionScheme: PKEncryptionScheme.RSA_V2)
        } else {
            config = PKAddPaymentPassRequestConfiguration.init(encryptionScheme: PKEncryptionScheme.ECC_V2)
        }
                
        guard let config = config else {
            NSLog("PKAddPaymentPassRequestConfiguration is null")
            return
        }
        
        config.cardholderName = "John"
        config.primaryAccountSuffix = "9999" //last 4 or 5digits of card
        config.localizedDescription = "This will add the card to Apple Pay"
        config.primaryAccountIdentifier = "test"
        config.paymentNetwork = PKPaymentNetwork(rawValue: "VISA")


        guard let controller = PKAddPaymentPassViewController.init(requestConfiguration: config, delegate: self) else {
            NSLog("PKAddPaymentPassViewController is null")
            return
        }

        NSLog("PKAddPaymentPassViewController instantiated")

        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            NSLog("Root VC unavailable")
            return
        }

        NSLog("Presenting PKAddPaymentPassViewController...")

        rootVC.present(controller, animated: true)
        //_invokeAddButtonPressed()
    }
}

public class SwiftFlutterWalletPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_wallet_handler", binaryMessenger: registrar.messenger())

    let factory = PKAddPassButtonNativeViewFactory(messenger: registrar.messenger(), channel: channel)
    registrar.register(factory, withId: "PKAddPassButton")

    let instance = SwiftFlutterWalletPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if (call.method == "canAddPaymentPass") {
          return result(PKAddPaymentPassViewController.canAddPaymentPass())
      }
      
    return result(FlutterMethodNotImplemented)
  }
}
