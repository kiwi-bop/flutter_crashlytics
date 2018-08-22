package com.kiwi.fluttercrashlytics

import android.app.Activity
import android.os.Bundle
import com.crashlytics.android.Crashlytics
import io.fabric.sdk.android.Fabric

class CrashActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
        super.onCreate(savedInstanceState)
        Fabric.with(this, Crashlytics())
        val cause = intent.getStringExtra("cause")
        val message = intent.getStringExtra("message")
        val traces: List<List<Any>> = (intent.extras.getSerializable("trace") as? Array<List<Any>> ?: arrayOf()).toList()

        val data = HashMap<String, Any>()
        data["cause"] = cause
        data["message"] = message
        data["trace"] = traces
        throw Utils.createException(data)
    }
}
