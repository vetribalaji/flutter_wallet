import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class FlutterWallet {
  static const MethodChannel _channel = const MethodChannel('flutter_wallet_handler');

  static final FlutterWallet _instance = FlutterWallet._internal();

  /// Associate each rendered Widget to its `onPressed` event handler
  static final Map<String, FutureOr<dynamic> Function(MethodCall)> _handlers = Map();

  static FutureOr<PKAddPaymentPassRequest> Function(List<String>, String, String)? _applePayOnDataHandler;

  // Returns whether this app can add payment passes or not on iOS.
  static Future<bool> canAddPaymentPass() async {
    if (Platform.isIOS) return (await _channel.invokeMethod('canAddPaymentPass')) == true;
    return false;
  }

  // For Android only. Adds a card to Google Pay.
  static Future<void> initiateGooglePayCardFlow({required String displayName, required String phoneNumber, required FutureOr<GooglePayRequest> Function(String walletId, String deviceId) onData}) async {
    final walletId = await getGooglePayWalletId();
    final hardwareId = await getGooglePayStableHardwareId();
    final response = await onData(walletId, hardwareId);

    await _channel.invokeMethod('addCardToGooglePay', {
      "displayName": displayName,
      "last4": response.last4,
      "opaquePaymentCard": response.opaquePaymentCard,
      "phoneNumber": phoneNumber,
      "address": response.address == null ? null : {"addressLine1": response.address!.addressLine1, "addressLine2": response.address!.addressLine2, "city": response.address!.city, "country": response.address!.country, "postalCode": response.address!.postalCode, "administrativeArea": response.address!.administrativeArea}
    });
  }

  // For iOS. At least one of cardholder name or primaryAccountSuffix must be supplied.
  static Future<dynamic> initiateiOSAddPaymentPassFlow(
      {String? cardholderName,
      String? primaryAccountSuffix,
      String? localizedDescription,
      String? primaryAccountIdentifier,
      required PaymentNetwork paymentNetwork,
      required FutureOr<PKAddPaymentPassRequest> Function(List<String> certificates, String nonce, String nonceSignature) onData}) async {
    _applePayOnDataHandler = onData;

    try {
      final response = await _channel.invokeMethod('initiateAddPaymentPassFlow', {
        "cardholderName": cardholderName,
        "primaryAccountSuffix": primaryAccountSuffix,
        "localizedDescription": localizedDescription,
        "primaryAccountIdentifier": primaryAccountIdentifier,
        "paymentNetwork": paymentNetwork.name,
      });

      return response;
    } finally {
      _applePayOnDataHandler = null;
    }
  }

  static Future<String> getGooglePayWalletId() async => await _channel.invokeMethod('getGooglePayWalletId');

  static Future<String> getGooglePayStableHardwareId() async => await _channel.invokeMethod('getStableHardwareId');
  
  factory FlutterWallet() => _instance;

  FlutterWallet._internal() {
    _initMethodCallHandler();
  }

  void _initMethodCallHandler() => _channel.setMethodCallHandler(_handleCalls);

  Future<dynamic> _handleCalls(MethodCall call) async {
    if (call.method == "onApplePayDataReceived" && call.arguments is Map) {
      if (_applePayOnDataHandler != null) {
        final List<String> certs = (call.arguments["certificatesBase64"] as List<dynamic>).map((e) => e.toString()).toList(growable: false);
        final String nonce = call.arguments["nonceBase64"].toString();
        final String nonceSignature = call.arguments["nonceSignatureBase64"].toString();

        final req = await _applePayOnDataHandler!(certs, nonce, nonceSignature);
        return <String, dynamic>{"encryptedPassData": req.encryptedPassData, "activationData": req.activationData, "ephemeralPublicKey": req.ephemeralPublicKey};
      }
    } else if (call.method == "onApplePayFinished") {}

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

class GooglePayRequest {
  final GoogleUserAddress? address;
  final String last4;
  final String opaquePaymentCard;

  const GooglePayRequest(this.last4, this.opaquePaymentCard, this.address);
}

class GoogleUserAddress {
  final String addressLine1, addressLine2, city, country, postalCode, administrativeArea;

  const GoogleUserAddress({required this.administrativeArea, required this.addressLine1, required this.addressLine2, required this.city, required this.country, required this.postalCode});
}

enum PaymentNetwork {
  amex, visa, masterCard, JCB, discover, electron, maestro
}
