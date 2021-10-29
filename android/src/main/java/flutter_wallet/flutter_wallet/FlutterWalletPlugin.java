package flutter_wallet.flutter_wallet;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.google.android.gms.tapandpay.TapAndPay;
import com.google.android.gms.tapandpay.TapAndPayClient;
import com.google.android.gms.tapandpay.issuer.PushTokenizeRequest;
import com.google.android.gms.tapandpay.issuer.UserAddress;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;

import java.nio.charset.StandardCharsets;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** FlutterWalletPlugin */
public class FlutterWalletPlugin implements FlutterPlugin, MethodCallHandler,ActivityAware  {
  private MethodChannel channel;
  private TapAndPayClient tapAndPayClient;
  private Activity activity;
  private static final int REQUEST_CODE_PUSH_TOKENIZE = 3;


  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_wallet_handler");
    tapAndPayClient = TapAndPay.getClient(flutterPluginBinding.getApplicationContext());
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case "getGooglePayWalletId":
        tapAndPayClient.getActiveWalletId().addOnCompleteListener(new OnCompleteListener<String>() {
          @Override
          public void onComplete(@NonNull Task<String> task) {
            if (task.isSuccessful()) {
              result.success(task.getResult());
            } else {
              String message = task.getException().getLocalizedMessage();
              result.error("0",message,null);
            }
          }
        });
        break;
      case "addCardToGooglePay":
        Map<String,String> address = call.argument("address");
        String name = call.argument("name");
        String last4 = call.argument("last4");
        String opc = call.argument("opaquePaymentCard");
        String phoneNumber = call.argument("phoneNumber");

        UserAddress userAddress =
                UserAddress.newBuilder()
                        .setName(name)
                        .setAddress1(address.get("addressLine1"))
                        .setAddress2(address.get("addressLine2"))
                        .setLocality(address.get("city"))
                        .setCountryCode(address.get("country"))
                        .setPostalCode(address.get("postalCode"))
                        .setPhoneNumber(phoneNumber)
                        .build();

        PushTokenizeRequest pushTokenizeRequest =
                new PushTokenizeRequest.Builder()
                        .setOpaquePaymentCard(opc.getBytes())
                        .setNetwork(TapAndPay.CARD_NETWORK_VISA)
                        .setTokenServiceProvider(TapAndPay.TOKEN_PROVIDER_VISA)
                        .setDisplayName(name)
                        .setLastDigits(last4)
                        .setUserAddress(userAddress)
                        .build();

        tapAndPayClient.pushTokenize(activity, pushTokenizeRequest, REQUEST_CODE_PUSH_TOKENIZE);
        break;
      default: result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() { }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) { }

  @Override
  public void onDetachedFromActivity() { }
}
