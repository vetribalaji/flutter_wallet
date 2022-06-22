package flutter_wallet.flutter_wallet;

import android.app.Activity;
import android.app.TaskInfo;
import android.content.Intent;

import android.util.Base64;
import android.util.Log;
import androidx.annotation.NonNull;

import com.google.android.gms.tapandpay.TapAndPay;
import com.google.android.gms.tapandpay.TapAndPayClient;
import com.google.android.gms.tapandpay.issuer.PushTokenizeRequest;
import com.google.android.gms.tapandpay.issuer.TokenInfo;
import com.google.android.gms.tapandpay.issuer.UserAddress;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/**
 * FlutterWalletPlugin
 */
public class FlutterWalletPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private static final int REQUEST_CODE_PUSH_TOKENIZE = 99927200;

    private MethodChannel channel;
    private TapAndPayClient tapAndPayClient;
    private Activity activity;
    private Result tokenizeResult;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_wallet_handler");
        tapAndPayClient = TapAndPay.getClient(flutterPluginBinding.getApplicationContext());
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
        switch (call.method) {
            case "getAddedCards":
                Log.d("FlutterWallet", "Calling listTokens...");
                tapAndPayClient.listTokens().addOnCompleteListener(new OnCompleteListener<List<TokenInfo>>() {
                    @Override
                    public void onComplete(@NonNull Task<List<TokenInfo>> task) {
                        if (task.isSuccessful()) {
                            final List<TokenInfo> taskInfoResult = task.getResult();
                            Log.d("FlutterWallet", "listTokens succeeded, found " + taskInfoResult.size() + " cards");
                            final List<Map<String, Object>> tokens = new ArrayList<>();
                            for (TokenInfo tokenInfo : taskInfoResult) {
                                Map<String, Object> map = new HashMap<>();
                                map.put("fpanLastFour", tokenInfo.getFpanLastFour());
                                map.put("issuerName", tokenInfo.getIssuerName());
                                map.put("network", tokenInfo.getNetwork());
                                map.put("isDefault", tokenInfo.getIsDefaultToken());

                                tokens.add(map);
                            }

                            result.success(tokens);
                        } else {
                            String message = task.getException().getLocalizedMessage();
                            result.error("-1", message, null);
                        }
                    }
                });

                break;
            case "getStableHardwareId":
                tapAndPayClient.getStableHardwareId().addOnCompleteListener(new OnCompleteListener<String>() {
                    @Override
                    public void onComplete(@NonNull Task<String> task) {
                        if (task.isSuccessful()) {
                            result.success(task.getResult());
                        } else {
                            String message = task.getException().getLocalizedMessage();
                            result.error("-1", message, null);
                        }
                    }
                });
                break;
            case "getGooglePayWalletId":
                tapAndPayClient.getActiveWalletId().addOnCompleteListener(new OnCompleteListener<String>() {
                    @Override
                    public void onComplete(@NonNull Task<String> task) {
                        if (task.isSuccessful()) {
                            result.success(task.getResult());
                        } else {
                            String message = task.getException().getLocalizedMessage();
                            result.error("-1", message, null);
                        }
                    }
                });
                break;
            case "addCardToGooglePay":
                Map<String, String> address = call.argument("address");

                UserAddress.Builder builder = UserAddress.newBuilder();

                builder.setName((String) call.argument("displayName"));
                builder.setPhoneNumber((String) call.argument("phoneNumber"));

                if (address != null) {
                    builder.setAddress1(address.get("addressLine1"))
                            .setAddress2(address.get("addressLine2"))
                            .setLocality(address.get("city"))
                            .setCountryCode(address.get("country"))
                            .setAdministrativeArea(address.get("administrativeArea"))
                            .setPostalCode(address.get("postalCode"));
                }

                String opaquePaymentCard = call.argument("opaquePaymentCard").toString();
                final String last4Digits = call.argument("last4").toString();
                final String displayName = call.argument("displayName").toString();

                final PushTokenizeRequest pushTokenizeRequest =
                        new PushTokenizeRequest.Builder()
                                .setOpaquePaymentCard(opaquePaymentCard.getBytes())
                                .setNetwork(TapAndPay.CARD_NETWORK_VISA)
                                .setTokenServiceProvider(TapAndPay.TOKEN_PROVIDER_VISA)
                                .setDisplayName(displayName)
                                .setLastDigits(last4Digits)
                                .setUserAddress(builder.build())
                                .build();

                tokenizeResult = result;
                tapAndPayClient.pushTokenize(activity, pushTokenizeRequest, REQUEST_CODE_PUSH_TOKENIZE);

                break;
            default:
                result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        binding.addActivityResultListener(this);
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_CODE_PUSH_TOKENIZE) {
            if (resultCode == Activity.RESULT_OK) {
                if (tokenizeResult != null) tokenizeResult.success(null);
            } else {
                if (tokenizeResult != null) tokenizeResult.error("-1", "Card provisioning failed.", null);
            }

            tokenizeResult = null;

            return true;
        }

        return false;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }
}
