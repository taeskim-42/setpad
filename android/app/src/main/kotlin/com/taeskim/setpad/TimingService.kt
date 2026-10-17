package com.taeskim.setpad

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log

/// Android's counterpart of the iOS keep-alive loop (ios/Runner/TimingBridge.swift):
/// while a timer runs (TimingBridge's `active`) the process is a foreground
/// service, so it is not cached and frozen in the background, and a partial
/// wake lock keeps the CPU awake between cues with the screen off. Without it
/// the Dart ticker stops and the run silently drifts.
///
/// Main thread only; the bridge and the service share the process.
class TimingService : Service() {
    companion object {
        private const val TAG = "TimingService"
        private const val CHANNEL = "timing"
        private const val NOTIFICATION = 7301
        // A lost stop can never hold the CPU awake longer than this.
        private const val WAKE_TIMEOUT_MS = 3 * 60 * 60 * 1000L

        private var wanted = false
        private var running: TimingService? = null
        private val handler = Handler(Looper.getMainLooper())
        private val ending = Runnable { if (!wanted) running?.end() }

        /// Best effort, like the iOS keep-alive: if Android refuses (the app is in
        /// the background, e.g. a partner's run arriving), the timer runs without
        /// it and the next active configure tries again.
        fun start(context: Context) {
            handler.removeCallbacks(ending)
            if (wanted) return
            wanted = true
            if (running != null) return
            try {
                context.startForegroundService(Intent(context, TimingService::class.java))
            } catch (e: Exception) {
                // ForegroundServiceStartNotAllowedException is an IllegalStateException.
                wanted = false
                Log.w(TAG, "not started", e)
            }
        }

        /// [lingerMs]: keep the process awake that long first, so the last cue and
        /// the words queued behind it (bridge playVoice) still sound with the
        /// screen off. No stopService: stopping before startForeground ran would
        /// crash the app ("did not then call startForeground"). A service still
        /// starting sees [wanted] false and ends itself right after startForeground.
        fun stop(lingerMs: Long = 0) {
            wanted = false
            handler.removeCallbacks(ending)
            if (lingerMs > 0) handler.postDelayed(ending, lingerMs) else running?.end()
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        running = this
        try {
            val notification = notification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(NOTIFICATION, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startForeground refused", e)
            wanted = false // the next active configure tries again
            end()
            return START_NOT_STICKY
        }
        if (!wanted) { end(); return START_NOT_STICKY }
        if (wakeLock == null) {
            wakeLock = (getSystemService(POWER_SERVICE) as PowerManager)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "setpad:timing")
                .apply { setReferenceCounted(false); acquire(WAKE_TIMEOUT_MS) }
        }
        return START_NOT_STICKY
    }

    private fun notification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, getString(R.string.timing_channel), NotificationManager.IMPORTANCE_LOW)
                .apply { setShowBadge(false); setSound(null, null); enableVibration(false) }
        )
        // The launcher's own intent: brings the running task to the front, no second activity.
        val open = packageManager.getLaunchIntentForPackage(packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
        val tap = open?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_timer)
            .setContentTitle(getString(R.string.timing_running))
            .setContentIntent(tap)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
                }
            }
            .build()
    }

    private fun end() {
        release()
        runCatching { stopForeground(STOP_FOREGROUND_REMOVE) }
        stopSelf()
        if (running === this) running = null
    }

    private fun release() {
        wakeLock?.let { if (it.isHeld) runCatching { it.release() } }
        wakeLock = null
    }

    override fun onDestroy() {
        release()
        if (running === this) running = null
        super.onDestroy()
    }
}
