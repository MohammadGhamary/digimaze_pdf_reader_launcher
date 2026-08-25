package com.vnegar.digimaze_pdf_reader_launcher;

import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import com.foxit.sdk.common.Constants;
import com.foxit.sdk.common.Library;
import org.json.JSONObject;
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
      case "initialize":
        initialize(call, result);
        break;
      case "openDocument":
        openDocument(call, result);
        break;
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

  private void openDocument(MethodCall call, Result result) {

    String path = call.argument("path");
    String password = call.argument("password");
    Integer bookId = call.argument("bookId");
    String bookTitle = call.argument("bookTitle");
    String bookCategory = call.argument("bookCategory");
    String bookName = call.argument("bookName");
    String bookAuthorS = call.argument("bookAuthorS");
    String bookPublisherK = call.argument("bookPublisherK");
    String bookTranslatorE = call.argument("bookTranslatorE");
    HashMap<String, Object> configurationsMap = call.argument("configurations");

    if (path == null || path.trim().isEmpty()) {
      result.error("" + Constants.e_ErrParam,"Invalid path", Constants.e_ErrParam);
      return;
    }

    if (activity == null) {
      result.error("-1","The Activity is null", -1);
      return;
    }

    try {
      String translatorKey = ObfuscationUtil.decrypt(bookTranslatorE, bookTitle, bookId != null ? bookId : 0);
      String bookAuthorSD = ObfuscationUtil.decrypt(bookAuthorS, bookTitle, bookId != null ? bookId : 0);
      String bookPublisherKD = ObfuscationUtil.decrypt(bookPublisherK, bookTitle, bookId != null ? bookId : 0);

      if (translatorKey == null) {
        errorCode = Constants.e_ErrUnknown;
        result.error("" + errorCode, "Failed", errorCode);
        return;
      }

      String sn = NativeCrypto.nativeDecryptLic(translatorKey, NativeCrypto.nativeDecryptLic(translatorKey, bookAuthorSD));
      String key = NativeCrypto.nativeDecryptLic(translatorKey, bookPublisherKD);

      if (sn == null || key == null) {
        errorCode = Constants.e_ErrUnknown;
        result.error("" + errorCode, "Failed", errorCode);
        return;
      }

      errorCode = Library.initialize(sn, key);
    } catch (Exception e) {
      errorCode = Constants.e_ErrUnknown;
      return;
    }

    if (errorCode != Constants.e_ErrSuccess) {
      result.error("" + errorCode,"Failed to initialize Foxit Library", errorCode);
      return;
    }

    JSONObject configurations = new JSONObject(configurationsMap != null ? configurationsMap : new HashMap<>());

    Intent intent = new Intent(activity, PDFReaderActivity.class);
    Bundle bundle = new Bundle();
    bundle.putInt("type", 0);
    bundle.putString("path", path);
    bundle.putString("password", password);
    bundle.putInt("bookId", bookId != null ? bookId : 0);
    bundle.putString("bookTitle", bookTitle);
    bundle.putString("bookName", bookName);
    bundle.putString("bookCategory", bookCategory);
    bundle.putString("configurations", configurations.toString());
    intent.putExtras(bundle);

    activity.startActivity(intent);
    result.success(true);
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
      public void onActivityStarted(@NonNull Activity activity) {}
      @Override
      public void onActivityResumed(@NonNull Activity activity) {}
      @Override
      public void onActivityPaused(@NonNull Activity activity) {}
      @Override
      public void onActivityStopped(@NonNull Activity activity) {}
      @Override
      public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle bundle) {}
    });
  }
}
