package io.github.heichan2000.tomo

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // What the notifications package can't say about the permission
    // (spec §11.4): which Android this is, and whether the last refusal was
    // a real answer or the dialog was dismissed. And the timer buzz
    // (spec §11.5), which Flutter can only play as a short bump here.
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
                    "buzz" -> result.success(buzz(call.argument<Int>("ms")!!.toLong()))
                    else -> result.notImplemented()
                }
            }
    }

    // One buzz that obeys the phone's notification vibration, as Tomo's own
    // notifications do: silent mode and Do Not Disturb stop it, and the
    // notification vibration strength sets how strong it is (C157). Says
    // false when silent or Do Not Disturb keeps it quiet, so the evolution
    // can play its tap instead (C167).
    private fun buzz(ms: Long): Boolean {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val notifications =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (audio.ringerMode == AudioManager.RINGER_MODE_SILENT ||
            notifications.currentInterruptionFilter >
            NotificationManager.INTERRUPTION_FILTER_ALL
        ) {
            return false
        }
        val vibrator = if (Build.VERSION.SDK_INT >= 31) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager)
                .defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!vibrator.hasVibrator()) return true
        val effect = VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE)
        if (Build.VERSION.SDK_INT >= 33) {
            vibrator.vibrate(
                effect,
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_NOTIFICATION),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(
                effect,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build(),
            )
        }
        return true
    }
}
