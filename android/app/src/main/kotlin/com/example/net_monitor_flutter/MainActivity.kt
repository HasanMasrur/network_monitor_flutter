package com.example.net_monitor_flutter

import android.content.Context
import android.net.*
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

  private val TAG = "NetMonitor"
  private val EVENT_CHANNEL = "app.network/events"
  private val METHOD_CHANNEL = "app.network/methods"

  private val mainHandler = Handler(Looper.getMainLooper())

  private var sink: EventChannel.EventSink? = null
  private lateinit var cm: ConnectivityManager
  private var last: String? = null

  private val callback = object : ConnectivityManager.NetworkCallback() {
    override fun onAvailable(network: Network) {
      Log.d(TAG, "onAvailable")
      push(currentStatus())
    }

    override fun onLost(network: Network) {
      Log.d(TAG, "onLost")
      push(currentStatus())
    }

    override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
      Log.d(TAG, "onCapabilitiesChanged: $caps")
      push(statusFromCaps(caps))
    }
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
      .setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          sink = events
          Log.d(TAG, "EventChannel onListen")
          push(currentStatus())
          register()
        }

        override fun onCancel(arguments: Any?) {
          Log.d(TAG, "EventChannel onCancel")
          sink = null
          unregister()
        }
      })

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "getCurrentStatus" -> result.success(currentStatus())
          else -> result.notImplemented()
        }
      }
  }

  private fun register() {
    try {
      val req = NetworkRequest.Builder()
        .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        .build()

      cm.registerNetworkCallback(req, callback)
      Log.d(TAG, "NetworkCallback registered")
    } catch (e: Exception) {
      Log.e(TAG, "register error: ${e.message}", e)
    }
  }

  private fun unregister() {
    try {
      cm.unregisterNetworkCallback(callback)
      Log.d(TAG, "NetworkCallback unregistered")
    } catch (_: Exception) {}
  }

  private fun currentStatus(): String {
    return try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val network = cm.activeNetwork ?: return "disconnected"
        val caps = cm.getNetworkCapabilities(network) ?: return "disconnected"
        statusFromCaps(caps)
      } else {
        @Suppress("DEPRECATION")
        val info = cm.activeNetworkInfo
        @Suppress("DEPRECATION")
        if (info != null && info.isConnected) "connected" else "disconnected"
      }
    } catch (_: Exception) {
      "disconnected"
    }
  }

  private fun statusFromCaps(caps: NetworkCapabilities): String {
    val hasInternet = caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    val validated = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    } else true
    return if (hasInternet && validated) "connected" else "disconnected"
  }

  private fun push(status: String) {
    if (status == last) return
    last = status
    Log.d(TAG, "push: $status")

    // ✅ MUST send to Flutter on MAIN THREAD
    mainHandler.post {
      sink?.success(status)
    }
  }
}
