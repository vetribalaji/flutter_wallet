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

class PKAddPassButtonNativeView: NSObject, FlutterPlatformView {
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
        let passButton = PKAddPassButton(addPassButtonStyle: PKAddPassButtonStyle.black)
        passButton.frame = CGRect(x: 0, y: 0, width: _width, height: _height)
        passButton.addTarget(self, action: #selector(passButtonAction), for: .touchUpInside)
        _view.addSubview(passButton)
    }

    @objc func passButtonAction() {
        _channel.invokeMethod("onApplePayButtonPressed", arguments: ["key": _key])
    }
}

public class SwiftFlutterWalletPlugin: NSObject, FlutterPlugin, PKAddPaymentPassViewControllerDelegate {
  private var channel: FlutterMethodChannel!
  private var initiateAddPaymentPassFlowResult: FlutterResult?
  private let pkPassLibrary = PKPassLibrary.init()
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_wallet_handler", binaryMessenger: registrar.messenger())

    let factory = PKAddPassButtonNativeViewFactory(messenger: registrar.messenger(), channel: channel)
    registrar.register(factory, withId: "PKAddPassButton")

    let instance = SwiftFlutterWalletPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if (call.method == "canAddPaymentPass") {
          return result(PKAddPaymentPassViewController.canAddPaymentPass())
      } else if (call.method == "initiateAddPaymentPassFlow") {
          let dict = call.arguments as! Dictionary<String, Any?>
          let res = SwiftFlutterWalletPlugin.initiateAddPaymentPassFlow(
            dict["cardholderName"] as? String,
            dict["primaryAccountSuffix"] as? String,
            dict["localizedDescription"] as? String,
            dict["primaryAccountIdentifier"] as? String,
            dict["paymentNetwork"] as? String,
            self
          )
          
          if (res != nil) {
              result(res)
          } else {
              initiateAddPaymentPassFlowResult = result
          }
          
          return
      } else if (call.method == "getAddedCards") {
          let passes = pkPassLibrary.passes(of: PKPassType.secureElement)
          NSLog("Passes queried, found " + String(passes.count) + " passes.")
          
          let res: [[String: Any]] = passes.filter({ pass in pass.secureElementPass != nil }).map { pass -> [String: Any] in
              let dict: [String: Any] = [
                "fpanLastFour": pass.secureElementPass!.primaryAccountNumberSuffix,
                "issuerName": pass.organizationName,
                "network": "",
                "isDefault": false
              ]
              return dict
          }
          
          result(res)
      }
          
      return result(FlutterMethodNotImplemented)
  }
    
    public func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, generateRequestWithCertificateChain certificates: [Data], nonce: Data, nonceSignature: Data, completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void) {
        NSLog("Apple Wallet data received.")
        
        let map: [String: Any?] = ["certificatesBase64": certificates.map({ e in e.base64EncodedString()}), "nonceBase64": nonce.base64EncodedString(), "nonceSignatureBase64": nonceSignature.base64EncodedString()]

        channel.invokeMethod("onApplePayDataReceived", arguments: map, result: { result in
            let paymentPassRequest = PKAddPaymentPassRequest.init()
            guard let resultMap = result as? [String: String?] else {
                return
            }

            NSLog("Received payment pass data, sending back to Apple")
            paymentPassRequest.encryptedPassData = Data.init(base64Encoded: resultMap["encryptedPassData"]!!)
            paymentPassRequest.activationData = Data.init(base64Encoded: resultMap["activationData"]!!)
            paymentPassRequest.ephemeralPublicKey = Data.init(base64Encoded: resultMap["ephemeralPublicKey"]!!)
            handler(paymentPassRequest)
        })
    }
    
    public func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, didFinishAdding pass: PKPaymentPass?, error: Error?) {
        let passDict: [String: Any?] = [
            "passActivationState": pass?.passActivationState.rawValue,
            "primaryAccountIdentifier": pass?.primaryAccountIdentifier,
            "primaryAccountNumberSuffix": pass?.primaryAccountNumberSuffix,
            "deviceAccountIdentifier": pass?.deviceAccountIdentifier,
            "deviceAccountNumberSuffix": pass?.deviceAccountNumberSuffix,
            "devicePassIdentifier": pass?.devicePassIdentifier,
            "pairedTerminalIdentifier": pass?.pairedTerminalIdentifier
        ]
        
        if (initiateAddPaymentPassFlowResult != nil) {
            initiateAddPaymentPassFlowResult?(error != nil ? FlutterError.init(code: "-3", message: error?.localizedDescription, details: nil) : passDict)
        } else {
            let resultDict: [String: Any?] = [
                "error": error?.localizedDescription,
                "pass": pass == nil ? nil : passDict
            ]
            
            channel.invokeMethod("onApplePayFinished", arguments: resultDict, result: nil)
        }
        
        initiateAddPaymentPassFlowResult = nil
        
        let rootVC = UIApplication.shared.keyWindow?.rootViewController
        rootVC?.dismiss(animated: true, completion: nil)
    }
    
    public static func initiateAddPaymentPassFlow(_ cardholderName: String?, _ primaryAccountSuffix: String?, _ localizedDescription: String?, _ primaryAccountIdentifier: String?, _ paymentNetwork: String?, _ delegate: PKAddPaymentPassViewControllerDelegate) -> FlutterError? {
        if (!PKAddPaymentPassViewController.canAddPaymentPass()) {
            NSLog("PKAddPaymentPassViewController canAddPaymentPass returned false")
            return FlutterError.init(code: "-1", message: "canAddPaymentPass returned false", details: nil)
        }
        
        guard let config: PKAddPaymentPassRequestConfiguration = PKAddPaymentPassRequestConfiguration.init(encryptionScheme: PKEncryptionScheme.ECC_V2) else {
            NSLog("PKAddPaymentPassRequestConfiguration is null")
            return FlutterError.init(code: "-2", message: "PKAddPaymentPassRequestConfiguration is null", details: nil)
        }

        let parsedPaymentNetwork: PKPaymentNetwork
        switch (paymentNetwork) {
        case "amex":
            parsedPaymentNetwork = .amex
            break
        case "visa":
            parsedPaymentNetwork = .visa
            break
        case "masterCard":
            parsedPaymentNetwork = .masterCard
            break
        case "JCB":
            if #available(iOS 10.1, *) {
                parsedPaymentNetwork = .JCB
            } else {
                return FlutterError.init(code: "-3", message: "JCB not available on this platform", details: nil)
            }
            break
        case "discover":
            parsedPaymentNetwork = .discover
            break
        case "electron":
            if #available(iOS 12.0, *) {
                parsedPaymentNetwork = .electron
            } else {
                return FlutterError.init(code: "-3", message: "electron not available on this platform", details: nil)
            }
            break
        case "maestro":
            if #available(iOS 12.0, *) {
                parsedPaymentNetwork = .maestro
            } else {
                return FlutterError.init(code: "-3", message: "maestro not available on this platform", details: nil)
            }
            break
        default:
            return FlutterError.init(code: "-3", message: "Invalid payment network", details: nil)
        }
            
        config.cardholderName = cardholderName
        config.primaryAccountSuffix = primaryAccountSuffix
        config.localizedDescription = localizedDescription
        config.primaryAccountIdentifier = primaryAccountIdentifier
        config.paymentNetwork = parsedPaymentNetwork

        guard let controller = PKAddPaymentPassViewController.init(requestConfiguration: config, delegate: delegate) else {
            NSLog("PKAddPaymentPassViewController is null")
            return FlutterError.init(code: "-2", message: "PKAddPaymentPassViewController is null", details: nil)
        }

        NSLog("PKAddPaymentPassViewController instantiated")

        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            NSLog("Root VC unavailable")
            return FlutterError.init(code: "-2", message: "Root view controller is null", details: nil)
        }

        NSLog("Presenting PKAddPaymentPassViewController...")

        rootVC.present(controller, animated: true)
        return nil
    }
}
