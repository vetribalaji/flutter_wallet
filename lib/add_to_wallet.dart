import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class AddToWallet {
  static const MethodChannel _channel = const MethodChannel('flutter_wallet_handler');

  static final AddToWallet _instance = AddToWallet._internal();

  /// Associate each rendered Widget to its `onPressed` event handler
  static final Map<String, FutureOr<dynamic> Function(MethodCall)> _handlers = Map();

  static FutureOr<PKAddPaymentPassRequest> Function(List<String>, String, String)? _applePayOnDataHandler;
  static FutureOr<void> Function()? _applePayOnFinishedHandler;

  static Future<void> addCardToGooglePay({dynamic args}) async {
    await _channel.invokeMethod('addCardToGooglePay', args);
  }

  // Returns whether this app can add payment passes or not on iOS.
  static Future<bool> canAddPaymentPass() async {
    return await _channel.invokeMethod('canAddPaymentPass');
  }

  // For iOS.
  static Future<dynamic> initiateAddPaymentPassFlow({required String cardholderName, required String primaryAccountSuffix, required String localizedDescription, required String primaryAccountIdentifier, required String paymentNetwork, required FutureOr<PKAddPaymentPassRequest> Function(List<String> certificates, String nonce, String nonceSignature) onData}) async {
    final requestId = Uuid().v4();

    _applePayOnDataHandler = onData;

    final response = await _channel.invokeMethod('initiateAddPaymentPassFlow', {
      "cardholderName": cardholderName,
      "primaryAccountSuffix": primaryAccountSuffix,
      "localizedDescription": localizedDescription,
      "primaryAccountIdentifier": primaryAccountIdentifier,
      "paymentNetwork": paymentNetwork,
      "requestId": requestId
    });

    return response;
  }

  static Future<String> getGooglePayWalletId() async => await _channel.invokeMethod('getGooglePayWalletId');

  factory AddToWallet() => _instance;

  AddToWallet._internal() {
    _initMethodCallHandler();
  }

  void _initMethodCallHandler() => _channel.setMethodCallHandler(_handleCalls);

  Future<dynamic> _handleCalls(MethodCall call) async {
    if (call.method == "onApplePayDataReceived" && call.arguments is Map) {
      if (_applePayOnDataHandler != null) {
        final certs = call.arguments["certificates"];
        final nonce = call.arguments["nonce"];
        final nonceSignature = call.arguments["nonceSignature"];

        final req = await _applePayOnDataHandler!(certs, nonce, nonceSignature);
        return <String, dynamic>{
          "encryptedPassData": req.encryptedPassData,
          "activationData": req.activationData,
          "ephemeralPublicKey": req.ephemeralPublicKey
        };
      }
    } else if (call.method == "onApplePayFinished") {

    }

    var handler = _handlers[call.arguments['key']];
    return handler != null ? await handler(call) : null;
  }

  Future<void> addHandler<T>(String key, FutureOr<T> Function(MethodCall) handler) async {
    _handlers[key] = handler;
  }

  invokeMethod(String method, dynamic args) {
    _channel.invokeMethod(method, args);
  }

  void removeHandler(String key) {
    _handlers.remove(key);
  }


}

class PKAddPaymentPassRequest {
  final String encryptedPassData;
  final String activationData;
  final String ephemeralPublicKey;

  const PKAddPaymentPassRequest(this.encryptedPassData, this.activationData, this.ephemeralPublicKey);
}

