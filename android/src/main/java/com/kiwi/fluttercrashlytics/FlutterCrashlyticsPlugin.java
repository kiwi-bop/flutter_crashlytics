package com.kiwi.fluttercrashlytics;

import android.content.Context;
import android.content.Intent;
import android.util.Log;
import com.crashlytics.android.Crashlytics;
import com.crashlytics.android.core.CrashlyticsCore;
import io.fabric.sdk.android.Fabric;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

import java.util.List;
import java.util.Map;

public class FlutterCrashlyticsPlugin implements MethodChannel.MethodCallHandler {

    private final Context context;

    public FlutterCrashlyticsPlugin(Context context) {
        this.context = context;
    }

    public static void registerWith(PluginRegistry.Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_crashlytics");
        channel.setMethodCallHandler(new FlutterCrashlyticsPlugin(registrar.context()));
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if (methodCall.method.equals("initialize")) {
            Fabric.with(context, new Crashlytics());
            result.success(null);
        } else {
            if (Fabric.isInitialized()) {
                onInitialisedMethodCall(methodCall, result);
            } else {
                result.success(null);
            }
        }
    }

    void onInitialisedMethodCall(MethodCall call, MethodChannel.Result result) {
        final CrashlyticsCore core = Crashlytics.getInstance().core;
        switch (call.method) {
            case "log":
                if (call.arguments instanceof String) {
                    core.log(call.arguments.toString());
                } else {
                    try {
                        final List<Object> info = (List<Object>) call.arguments;
                        core.log(parseStringOrEmpty(info.get(0)) + ": " + info.get(1) + " " + info.get(2));
                    } catch (ClassCastException ex) {
                        Log.d("FlutterCrashlytics", "" + ex.getMessage());
                    }
                }
                result.success(null);
                break;
            case "setInfo":
                final Object currentInfo = call.argument("value");
                if (currentInfo instanceof String) {
                    core.setString((String) call.argument("key"), (String) call.argument("value"));
                } else if (currentInfo instanceof Integer) {
                    core.setInt((String) call.argument("key"), (Integer) call.argument("value"));
                } else if (currentInfo instanceof Double) {
                    core.setDouble((String) call.argument("key"), (Double) call.argument("value"));
                } else if (currentInfo instanceof Boolean) {
                    core.setBool((String) call.argument("key"), (Boolean) call.argument("value"));
                } else if (currentInfo instanceof Float) {
                    core.setFloat((String) call.argument("key"), (Float) call.argument("value"));
                } else if (currentInfo instanceof Long) {
                    core.setLong((String) call.argument("key"), (Long) call.argument("value"));
                } else {
                    core.log("ignoring unknown type with key " + call.argument("key") + "and value "
                            + call.argument("value"));
                }
                result.success(null);
                break;
            case "setUserInfo":
                core.setUserEmail((String) call.argument("email"));
                core.setUserName((String) call.argument("name"));
                core.setUserIdentifier((String) call.argument("id"));
                result.success(null);
                break;
            case "reportCrash":
                final Map<String, Object> exception = (Map<String, Object>) call.arguments;
                final boolean forceCrash = tryParseForceCrash(exception.get("forceCrash"));
                final FlutterException throwable = Utils.create(exception);
                if (forceCrash) {
                    //Start a new activity to not crash directly under onMethod call, or it will crash JNI instead of a clean exception
                    final Intent intent = new Intent(context, CrashActivity.class);
                    intent.putExtra("exception", throwable);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

                    context.startActivity(intent);
                } else {
                    Log.d("Crashlytics", "this thing is reporting");
                    core.logException(throwable);
                }

                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    String parseStringOrEmpty(Object obj) {
        if (obj != null) {
            return obj.toString();
        }
        return "";
    }

    boolean tryParseForceCrash(Object object) {
        if (object instanceof Boolean) {
            return (boolean) object;
        }
        return false;
    }

}
