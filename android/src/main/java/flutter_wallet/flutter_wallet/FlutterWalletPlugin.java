package flutter_wallet.flutter_wallet;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.google.android.gms.tapandpay.TapAndPay;
import com.google.android.gms.tapandpay.TapAndPayClient;
import com.google.android.gms.tapandpay.issuer.PushTokenizeRequest;
import com.google.android.gms.tapandpay.issuer.UserAddress;

import java.nio.charset.StandardCharsets;

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
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case "getGooglePayWalletId":
        String walletId = tapAndPayClient.getActiveWalletId().getResult();
        result.success(walletId);
        //tapAndPayClient.pushTokenize(activity, pushTokenizeRequest, REQUEST_CODE_PUSH_TOKENIZE);
        break;
      case "addCardToGooglePay":
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
