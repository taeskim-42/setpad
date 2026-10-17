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

/// The workout being recorded keeps going in the background: while a timer
/// that sounds runs (TimingBridge's `keepAlive`: a workout run or a set rest,
/// not the set stage alone) the process is a foreground service of type
/// health (manifest), so it is not cached and frozen in the background.
/// Without it the Dart ticker stops and the run silently drifts.
///
/// The partial wake lock keeps the CPU awake between cues with the screen off,
/// but only when nothing else does: Android vitals counts it against the app
/// ("2 or more hours in a 24-hour period" is excessive, tracked "only if the
/// wake lock is held when the app is in the background or is running a
/// foreground service"). So it is held only while the app is not visible (a
/// visible app keeps the screen on) and no beat loop sounds (playing audio
/// keeps the CPU awake itself, and Android vitals "exempts wake locks created
/// by audio"), with a short timeout every bridge call renews.
///
/// Main thread only; the bridge and the service share the process.
class TimingService : Service() {
    companion object {
        private const val TAG = "TimingService"
        private const val CHANNEL = "timing"
        private const val NOTIFICATION = 7301
        // Every bridge call (keepAlive, configure, voice) renews the lock. The
        // longest stretch without one while a timer runs is just under 10 min:
        // a Tabata interval or a set rest is at most 600 s (TimingSpec.maxSeconds,
        // RestTimer.maxLength), and its end sends a cue, the last 3 s "ready"
        // ticks and a set rest's "ten_left" come before it. 11 min outlasts that,
        // so the lock does not lapse mid-run, and a lost stop holds the CPU
        // awake 11 min at most.
        private const val WAKE_TIMEOUT_MS = 11 * 60 * 1000L

        private var wanted = false
        // The activity is started (onStart..onStop): the screen is on and the
        // app in front, the CPU needs no lock.
        private var visible = true
        // A beat loop is playing (TimingBridge's click track): audio holds the
        // CPU awake while it plays.
        private var clicking = false
        private var running: TimingService? = null
        private val handler = Handler(Looper.getMainLooper())
        private val ending = Runnable { if (!wanted) running?.end() }

        /// Best effort: if Android refuses (the app is in
        /// the background, e.g. a partner's run arriving), the timer runs without
        /// it until [retry] when the app comes to the front.
        fun start(context: Context) {
            handler.removeCallbacks(ending)
            wanted = true
            running?.let { it.awake(); return }
            launch(context)
        }

        /// A bridge call while a timer may run: whether a beat loop sounds now,
        /// and the lock's timeout starts over.
        fun renew(clicking: Boolean) {
            this.clicking = clicking
            running?.awake()
        }

        /// MainActivity onStart (true) / onStop (false).
        fun visible(shown: Boolean) {
            visible = shown
            running?.awake()
        }

        /// The activity resumed: a start refused in the background goes now.
        fun retry(context: Context) {
            if (wanted && running == null) launch(context)
        }

        private fun launch(context: Context) {
            try {
                context.startForegroundService(Intent(context, TimingService::class.java))
            } catch (e: Exception) {
                // ForegroundServiceStartNotAllowedException is an IllegalStateException.
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
            clicking = false
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
            // The health type constant exists from Android 14 (API 34); below,
            // the two-argument form takes the manifest's type.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
            } else {
                startForeground(NOTIFICATION, notification)
            }
        } catch (e: Exception) {
            // Not best effort, and not recoverable: started with
            // startForegroundService, so ending without startForeground makes
            // the system kill the app ("did not then call startForeground"),
            // and so does staying until its timeout. Not seen: the manifest
            // declares the type, its permission and HIGH_SAMPLING_RATE_SENSORS
            // (the health type's prerequisite, granted at install). Only a
            // refused start (start() above) is the skippable case.
            Log.w(TAG, "startForeground refused", e)
            wanted = false
            end()
            return START_NOT_STICKY
        }
        if (!wanted) { end(); return START_NOT_STICKY }
        awake()
        return START_NOT_STICKY
    }

    /// Holds the lock while the app is not visible and no beat sounds, with
    /// the timeout starting over (acquire on a non-counted lock that is held
    /// replaces its pending timeout); otherwise lets it go. A linger (stop's
    /// lingerMs, 6 s) follows the same rule and end() lets it go.
    private fun awake() {
        val lock = wakeLock ?: (getSystemService(POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "setpad:timing")
            .apply { setReferenceCounted(false) }
            .also { wakeLock = it }
        if (!visible && !clicking) runCatching { lock.acquire(WAKE_TIMEOUT_MS) }
        else if (lock.isHeld) runCatching { lock.release() }
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
        // Ongoing, but Android 14+ lets the user swipe it away. That only hides
        // it: the service and the timer go on (no delete intent), and it is
        // still listed in the Task Manager.
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
