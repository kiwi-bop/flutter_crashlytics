package com.kiwi.fluttercrashlytics

import android.app.Activity
import android.content.Intent
import com.crashlytics.android.Crashlytics
import io.fabric.sdk.android.Fabric
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar


class FlutterCrashlyticsPlugin(private val context: Activity) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_crashlytics")
            channel.setMethodCallHandler(FlutterCrashlyticsPlugin(registrar.activity()))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialise" -> {
                Fabric.with(context, Crashlytics())

                result.success(null)
            }
            else -> {
                if (Fabric.isInitialized()) {
                    onInitialisedMethodCall(call, result)
                } else {
                    // Should not result in an error. Otherwise Opt Out clients would need to handle errors
                    result.success(null)
                }
            }
        }
    }

    private fun onInitialisedMethodCall(call: MethodCall, result: Result) {
        val core = Crashlytics.getInstance().core
        when {
            call.method == "log" -> {
                if (call.arguments is String) {
                    core.log(call.arguments as String)
                } else {
                    val info = call.arguments as List<Any>
                    core.log(info[0] as Int, info[1] as String, info[2] as String)
                }
                result.success(null)
            }
            call.method == "setInfo" -> {
                val info = call.arguments as Map<String, Any>
                when (info["value"]) {
                    is String ->
                        core.setString(info["key"] as String, info["value"] as String)
                    is Int ->
                        core.setInt(info["key"] as String, info["value"] as Int)
                    is Double ->
                        core.setDouble(info["key"] as String, info["value"] as Double)
                    is Boolean ->
                        core.setBool(info["key"] as String, info["value"] as Boolean)
                    is Float ->
                        core.setFloat(info["key"] as String, info["value"] as Float)
                    is Long ->
                        core.setLong(info["key"] as String, info["value"] as Long)
                    else -> core.log("ignoring unknown type with key ${info["key"]} and value ${info["value"]}")
                }
                result.success(null)
            }
            call.method == "setUserInfo" -> {
                val info = call.arguments as Map<String, String>
                core.setUserEmail(info["email"])
                core.setUserName(info["name"])
                core.setUserIdentifier(info["id"])
                result.success(null)
            }
            call.method == "reportCrash" -> {
                val exception = (call.arguments as Map<String, Any>)
                val forceCrash = exception["forceCrash"] as? Boolean ?: false

                val throwable = Utils.create(exception)

                if (forceCrash) {
                    //Start a new activity to not crash directly under onMethod call, or it will crash JNI instead of a clean exception
                    val intent = Intent(context, CrashActivity::class.java).apply {
                        putExtra("exception", throwable)
                    }

                    context.startActivityForResult(intent, -1)
                } else {
                    core.logException(throwable)
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
