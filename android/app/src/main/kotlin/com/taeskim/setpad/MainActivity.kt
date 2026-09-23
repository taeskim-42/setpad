package com.taeskim.setpad

import io.flutter.embedding.android.FlutterFragmentActivity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Health Connect 의 권한 요청은 registerForActivityResult 를 쓴다. 그것을
// 부르려면 Activity 가 ComponentActivity 여야 해서 FlutterActivity 로는 안 된다.
class MainActivity : FlutterFragmentActivity() {
    private var timing: TimingBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        timing = TimingBridge(this, flutterEngine.dartExecutor.binaryMessenger)

        // 공유 시트. 글 한 줄(공동 루틴 초대 링크)을 올리는 것이 전부라 플러그인 없이 둔다.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "setpad/share")
            .setMethodCallHandler { call, result ->
                val text = call.argument<String>("text")
                if (call.method != "share" || text == null) return@setMethodCallHandler result.success(false)
                val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
                startActivity(Intent.createChooser(send, null))
                result.success(true)
            }
    }

    // 헬스 커넥트가 "이 앱이 권한을 왜 쓰는가" 를 물으면 건강 데이터 화면을 연다
    // (lib/health_page.dart). 홈을 띄우면 심사에서 설명이 없는 것으로 본다.
    private fun isRationale(i: Intent?) =
        i?.action == "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" ||
            i?.action == "android.intent.action.VIEW_PERMISSION_USAGE"

    override fun getInitialRoute(): String? =
        if (isRationale(intent)) "/health-data" else super.getInitialRoute()

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isRationale(intent)) flutterEngine?.navigationChannel?.pushRoute("/health-data")
    }

    override fun onPause() { timing?.interrupt(); super.onPause() }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        timing?.close(); timing = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
