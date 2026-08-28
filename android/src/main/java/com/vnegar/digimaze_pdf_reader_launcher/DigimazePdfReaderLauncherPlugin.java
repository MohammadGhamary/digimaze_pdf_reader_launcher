package com.vnegar.digimaze_pdf_reader_launcher;

import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;
import com.foxit.sdk.common.Constants;
import com.foxit.sdk.common.Library;

import org.json.JSONObject;

import java.io.File;
import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class DigimazePdfReaderLauncherPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private static final String TAG = "DigimazePdfReaderLauncherPlugin";
    private Activity activity;
    private int errorCode = Constants.e_ErrUnknown;

    private boolean isClaasicPdfReaderOpened = false;
    private boolean isAdvancedPdfReaderOpened = false;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "digimaze_pdf_reader_launcher");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "getFileContentUri": {
                String path = call.argument("path");
                if (path == null) {
                    result.error("INVALID_ARGUMENT", "Path cannot be null", null);
                    return;
                }

                File file = new File(path);
                String packageName = activity.getPackageName();
                Uri uri = FileProvider.getUriForFile(
                        activity.getApplicationContext(),
                        packageName + ".fileProvider",
                        file
                );

                result.success(uri.toString());
                break;
            }
            case "initialize":
                initialize(call, result);
                break;
            case "openDocumentWithClassicPdfReader":
                openDocumentWithClassicPdfReader(call, result);
                break;
            case "openDocumentWithAdvancedPdfReader": {
                openDocumentWithAdvancedPdfReader(call, result);
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        registerActivityLifecycleCallbacks();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        registerActivityLifecycleCallbacks();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        activity = null;
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }


    private void initialize(MethodCall call, Result result) {
        String sn = call.argument("sn");
        String key = call.argument("key");

        errorCode = Library.initialize(sn, key);
        result.success(errorCode);
    }

    private void openDocumentWithClassicPdfReader(MethodCall call, Result result) {

        PDFParams params = ParamDecryptor.decryptClassicPdfReaderParams(call.argument("params"));

        assert params != null;
        errorCode = Library.initialize(params.getLicSn(), params.getLicKey());
        if (errorCode != Constants.e_ErrSuccess) {
            result.error("" + errorCode, "Failed to initialize Foxit Library", errorCode);
            return;
        }

        HashMap<String, Object> configurationsMap = call.argument("configurations");
        JSONObject configurations = new JSONObject(configurationsMap != null ? configurationsMap : new HashMap<>());

        Intent intent = new Intent(activity, PDFReaderActivity.class);
        Bundle bundle = new Bundle();
        bundle.putSerializable("params", params);
        bundle.putString("configurations", configurations.toString());
        intent.putExtras(bundle);

        activity.startActivity(intent);

        isClaasicPdfReaderOpened = true;
        result.success(true);
    }

    private void openDocumentWithAdvancedPdfReader(MethodCall call, Result result) {
        String params = call.argument("params");
        String path = call.argument("path");

        if (params == null || path == null) {
            result.error("INVALID_ARGUMENT", "Parameters cannot be null", null);
            return;
        }

        Intent intent = new Intent();
        intent.setAction("com.vnegar.digimaze.OPEN_BOOK");
        intent.setDataAndType(Uri.parse(path), "application/pdf");
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
        intent.putExtra("params", params);

        try {
            isAdvancedPdfReaderOpened = true;
            activity.startActivity(intent);
            result.success(null);
        } catch (Exception e) {
            result.error("INTENT_ERROR", e.getMessage(), null);
        }
    }

    private void registerActivityLifecycleCallbacks() {
        activity.getApplication().registerActivityLifecycleCallbacks(new Application.ActivityLifecycleCallbacks() {
            @Override
            public void onActivityDestroyed(@NonNull Activity activity) {
                if (activity.getClass().getName().equals("com.vnegar.digimaze_pdf_reader_launcher.PDFReaderActivity")) {
                    new Handler(Looper.getMainLooper()).post(() -> {
                        channel.invokeMethod("documentClosed", null);
                    });

                }
            }

            @Override
            public void onActivityCreated(@NonNull Activity activity, Bundle bundle) {
                if (activity.getClass().getName().equals("com.vnegar.digimaze_pdf_reader_launcher.PDFReaderActivity")) {
                    activity.getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE);
                }
            }

            @Override
            public void onActivityStarted(@NonNull Activity activity) {
            }

            @Override
            public void onActivityResumed(@NonNull Activity activity) {
            }

            @Override
            public void onActivityPaused(@NonNull Activity activity) {
            }

            @Override
            public void onActivityStopped(@NonNull Activity activity) {
            }

            @Override
            public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle bundle) {
            }
        });
    }
}
