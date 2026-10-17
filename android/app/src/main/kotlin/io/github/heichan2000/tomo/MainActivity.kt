package io.github.heichan2000.tomo

import android.Manifest
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // What the notifications package can't say about the permission
    // (spec §11.4): which Android this is, and whether the last refusal was
    // a real answer or the dialog was dismissed.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tomo/notifications")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "shouldShowRationale" -> result.success(
                        Build.VERSION.SDK_INT >= 33 &&
                            shouldShowRequestPermissionRationale(
                                Manifest.permission.POST_NOTIFICATIONS,
                            ),
                    )
                    else -> result.notImplemented()
                }
            }
    }
}
