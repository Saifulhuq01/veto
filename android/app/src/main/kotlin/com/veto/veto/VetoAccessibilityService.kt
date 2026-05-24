package com.veto.veto

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

/**
 * VetoAccessibilityService — Deep Node Interceptor.
 *
 * Hooks into TYPE_WINDOW_CONTENT_CHANGED to detect and block features
 * within apps (e.g., YouTube Shorts, Instagram Reels) without blocking
 * the entire app.
 *
 * CRITICAL PERFORMANCE CONSTRAINTS:
 * 1. 300ms debounce via Handler.postDelayed — only the LAST event in a
 *    scroll burst triggers traversal. Without this, CPU would spike to 30%+.
 * 2. Package-level early-return — if no rules target the current package,
 *    zero work is done (< 0.01ms per event).
 * 3. findAccessibilityNodeInfosByText() is used instead of full tree walk —
 *    Android framework handles the O(n) traversal natively, which is
 *    significantly faster than manual recursion from Kotlin.
 * 4. The accessibility_service_config.xml filters events at the OS level
 *    to only YouTube and Instagram — we receive ZERO events from other apps.
 */
class VetoAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "VetoAccessibility"
        const val ACTION_RELOAD_RULES = "com.veto.veto.RELOAD_RULES"
        private const val DEBOUNCE_MS = 300L
        private const val COOLDOWN_MS = 2000L // Prevent rapid back-press spam
    }

    private lateinit var rulesEngine: VetoRulesEngine
    private val handler = Handler(Looper.getMainLooper())
    private var pendingRunnable: Runnable? = null
    private var lastBlockTimestamp = 0L
    private var overlayView: View? = null

    // Cached rules — reloaded on broadcast from MainActivity
    private var cachedRules: Map<String, List<String>> = emptyMap()

    /**
     * BroadcastReceiver to reload rules when the Flutter UI toggles a deep block.
     * Flow: Flutter toggle → MethodChannel → MainActivity writes SharedPrefs
     *       → sends broadcast → this receiver → reload cachedRules
     */
    private val rulesReloadReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d(TAG, "Broadcast received: reloading rules")
            reloadRules()
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility Service connected")
        rulesEngine = VetoRulesEngine(this)
        reloadRules()

        // Register broadcast receiver for real-time rule updates
        val filter = IntentFilter(ACTION_RELOAD_RULES)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(rulesReloadReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(rulesReloadReceiver, filter)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (!::rulesEngine.isInitialized) return

        val packageName = event.packageName?.toString() ?: return

        // 1. Strict Mode (Anti-Uninstall protection)
        if (packageName == "com.android.settings" && isStrictModeEnabled()) {
            val rootNode = rootInActiveWindow
            if (rootNode != null) {
                try {
                    val vetoNodes = rootNode.findAccessibilityNodeInfosByText("Veto")
                    if (!vetoNodes.isNullOrEmpty()) {
                        Log.d(TAG, "Blocking settings page access to Veto configuration")
                        executeBlock("Strict Mode: Anti-Uninstall Protection")
                        recycleNodes(vetoNodes)
                        rootNode.recycle()
                        return
                    }
                } catch (e: Exception) {
                    // ignore
                } finally {
                    try { rootNode.recycle() } catch (e: Exception) {}
                }
            }
        }

        val directivesEnabled = isDirectivesEnabled()

        // 2. Website Blocking in Browsers
        if (directivesEnabled && isBrowserApp(packageName) && isWebsiteBlockingEnabled()) {
            val rootNode = rootInActiveWindow
            if (rootNode != null) {
                try {
                    val blockedSites = getBlockedWebsites()
                    for (site in blockedSites) {
                        if (site.trim().isEmpty()) continue
                        val matchingNodes = rootNode.findAccessibilityNodeInfosByText(site)
                        if (!matchingNodes.isNullOrEmpty()) {
                            Log.d(TAG, "Blocking website: $site in browser $packageName")
                            executeBlock("Website Blocked: $site")
                            recycleNodes(matchingNodes)
                            rootNode.recycle()
                            return
                        }
                    }
                } catch (e: Exception) {
                    // ignore
                } finally {
                    try { rootNode.recycle() } catch (e: Exception) {}
                }
            }
        }

        // 3. App Limits Enforcement
        if (directivesEnabled) {
            val limits = getAppLimits()
            val limitRule = limits.firstOrNull { it.packageName == packageName && it.isActive }
            if (limitRule != null) {
                val usageMinutes = getAppUsageMinutesToday(this, packageName)
                if (usageMinutes >= limitRule.limitMinutes) {
                    Log.d(TAG, "Blocking $packageName because usage $usageMinutes >= limit ${limitRule.limitMinutes}")
                    executeBlock("Daily Limit Exceeded (${limitRule.limitMinutes}m)")
                    return
                }
            }
        }

        // 4. Wildcard rules and Deep Blocks
        val targets = cachedRules[packageName]
        if (!targets.isNullOrEmpty()) {
            if (targets.contains("*")) {
                // Wildcard app block: only runs if lockdown is active
                if (rulesEngine.isLockdownActive()) {
                    Log.d(TAG, "Blocking entire application $packageName immediately due to wildcard rule during active lockdown")
                    executeBlock("Application Blocked")
                    return
                }
            } else if (directivesEnabled) {
                // Deep block rule: runs if directives are enabled (even if lockdown is not active)
                pendingRunnable?.let { handler.removeCallbacks(it) }

                val runnable = Runnable {
                    performNodeScan(packageName, targets)
                }
                pendingRunnable = runnable
                handler.postDelayed(runnable, DEBOUNCE_MS)
            }
        }
    }

    /**
     * Scan the current window's node tree for target content descriptions.
     * Uses findAccessibilityNodeInfosByText() for efficient framework-level search.
     */
    private fun performNodeScan(packageName: String, targets: List<String>) {
        val rootNode = rootInActiveWindow ?: return

        try {
            for (target in targets) {
                // Search by text content — framework does the tree walk
                val matchingNodes = rootNode.findAccessibilityNodeInfosByText(target)

                if (matchingNodes.isNullOrEmpty()) {
                    // Try layout matching if direct text query is empty
                    if (checkNodeTreeForLayout(rootNode, packageName)) {
                        return
                    }
                    continue
                }

                // Validate: check if any matching node is actually visible/relevant
                for (node in matchingNodes) {
                    if (isRelevantNode(node, target, packageName)) {
                        Log.d(TAG, "Blocking triggered by node target matching '$target' in $packageName")
                        executeBlock(target)
                        recycleNodes(matchingNodes)
                        return
                    }
                }
                recycleNodes(matchingNodes)
            }
            
            // Also check layouts directly in case text search failed
            checkNodeTreeForLayout(rootNode, packageName)
            
        } catch (e: Exception) {
            Log.e(TAG, "Node scan traversal failed: ${e.message}")
        } finally {
            rootNode.recycle() // Guarantee rootNode is recycled to prevent binder leaks
        }
    }

    /**
     * Fallback layout scanner that checks node view IDs for direct player containers.
     * Uses fast view ID search first, then falls back to a safe recursive walk.
     */
    private fun checkNodeTreeForLayout(rootNode: AccessibilityNodeInfo, packageName: String): Boolean {
        val targets = when (packageName) {
            "com.google.android.youtube" -> listOf(
                "com.google.android.youtube:id/shorts_player",
                "com.google.android.youtube:id/shorts_video_layout",
                "com.google.android.youtube:id/reel_container",
                "com.google.android.youtube:id/shorts_control_container"
            )
            "com.instagram.android" -> listOf(
                "com.instagram.android:id/reels_viewer",
                "com.instagram.android:id/reels_video",
                "com.instagram.android:id/clips_video",
                "com.instagram.android:id/instagram_reels_tab"
            )
            else -> emptyList()
        }

        // 1. Fast path: search by exact view ID using framework-level search
        for (viewId in targets) {
            val matchingNodes = rootNode.findAccessibilityNodeInfosByViewId(viewId)
            if (!matchingNodes.isNullOrEmpty()) {
                Log.d(TAG, "Blocking triggered by fast view ID match: $viewId")
                executeBlock(if (packageName == "com.google.android.youtube") "YouTube Shorts" else "Instagram Reels")
                recycleNodes(matchingNodes)
                return true
            }
        }

        // 2. Slow path: safe depth-first search recursive traversal that recycles all child nodes
        return scanTreeRecursively(rootNode, packageName)
    }

    /**
     * Recursively traverses layout nodes, immediately recycling child instances to avoid binder leaks.
     */
    private fun scanTreeRecursively(node: AccessibilityNodeInfo?, packageName: String): Boolean {
        if (node == null) return false
        val viewId = node.viewIdResourceName ?: ""

        if (packageName == "com.google.android.youtube") {
            if (viewId.contains("shorts_player") || 
                viewId.contains("shorts_video_layout") || 
                viewId.contains("reel_container") ||
                viewId.contains("shorts_control_container")) {
                Log.d(TAG, "Blocking triggered by YouTube layout ID (traversal): $viewId")
                executeBlock("YouTube Shorts Player")
                return true
            }
        } else if (packageName == "com.instagram.android") {
            if (viewId.contains("reels_viewer") || 
                viewId.contains("reels_video") || 
                viewId.contains("clips_video") ||
                viewId.contains("instagram_reels_tab")) {
                Log.d(TAG, "Blocking triggered by Instagram layout ID (traversal): $viewId")
                executeBlock("Instagram Reels Player")
                return true
            }
        }

        val childCount = node.childCount
        for (i in 0 until childCount) {
            val child = node.getChild(i) ?: continue
            val found = scanTreeRecursively(child, packageName)
            child.recycle() // Clean up child node immediately
            if (found) return true
        }

        return false
    }

    /**
     * Validate that a found node is actually the target feature tab/section,
     * not just any text that happens to contain the word.
     */
    private fun isRelevantNode(node: AccessibilityNodeInfo, target: String, packageName: String): Boolean {
        val contentDesc = node.contentDescription?.toString() ?: ""
        val viewId = node.viewIdResourceName ?: ""
        val text = node.text?.toString() ?: ""

        val isDescMatch = contentDesc.contains(target, ignoreCase = true)
        val isTextMatch = text.contains(target, ignoreCase = true)

        val isSelected = node.isSelected || node.isFocused || node.isChecked

        // For player layout components, we don't require selections
        val isPlayerLayout = when (packageName) {
            "com.google.android.youtube" -> {
                viewId.contains("shorts", ignoreCase = true) || 
                viewId.contains("reel_container", ignoreCase = true)
            }
            "com.instagram.android" -> {
                viewId.contains("reels", ignoreCase = true) || 
                viewId.contains("clips", ignoreCase = true)
            }
            else -> false
        }

        if (isPlayerLayout) return true

        return when {
            viewId.contains("shorts_pivot_header", ignoreCase = true) -> true
            viewId.contains("reels_tab", ignoreCase = true) -> true
            isDescMatch && isSelected -> true
            isTextMatch && isSelected -> true
            contentDesc.equals("Shorts", ignoreCase = true) && node.isClickable -> true
            contentDesc.equals("Reels", ignoreCase = true) && node.isClickable -> true
            else -> false
        }
    }

    /**
     * Execute the block action: GLOBAL_ACTION_BACK + popup message overlay.
     */
    private fun executeBlock(target: String) {
        val now = System.currentTimeMillis()
        if (now - lastBlockTimestamp < COOLDOWN_MS) return
        lastBlockTimestamp = now

        // Navigate back — this exits the blocked feature
        performGlobalAction(GLOBAL_ACTION_BACK)

        // Show the beautiful native glassmorphic block overlay
        showBlockOverlay(target)
    }

    /**
     * Build and draw a beautiful native glassmorphic card overlay using accessibility window manager.
     */
    private fun showBlockOverlay(target: String) {
        handler.post {
            val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            
            // Remove previous overlay if any
            overlayView?.let {
                try {
                    wm.removeView(it)
                } catch (e: Exception) {
                    // Ignore
                }
                overlayView = null
            }

            // Outer wrapper FrameLayout
            val container = FrameLayout(this)

            // Setup LayoutParams for accessibility overlay (draws over all apps without SYSTEM_ALERT_WINDOW permission)
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.BOTTOM
                y = dpToPx(80) // Margin from bottom navigation/gesture area
                windowAnimations = android.R.style.Animation_InputMethod // Smooth slide up/down transition
            }

            // Beautiful glassmorphic linear layout card
            val card = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
                
                val pad = dpToPx(20)
                setPadding(pad, pad, pad, pad)
                
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#E60D0D11")) // 90% Obsidian dark base
                    cornerRadius = dpToPx(20).toFloat()
                    setStroke(dpToPx(1), Color.parseColor("#33FFFFFF")) // Subtly transparent white border
                }
            }

            // Center card width margin
            val cardParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                val margin = dpToPx(24)
                setMargins(margin, 0, margin, 0)
            }
            container.addView(card, cardParams)

            // Lock Icon
            val iconView = ImageView(this).apply {
                setImageResource(android.R.drawable.ic_lock_lock)
                setColorFilter(Color.parseColor("#FF6B6B")) // Coral tint
            }
            val iconParams = LinearLayout.LayoutParams(dpToPx(36), dpToPx(36)).apply {
                bottomMargin = dpToPx(12)
            }
            card.addView(iconView, iconParams)

            // Title "VETO LOCKDOWN ACTIVE"
            val titleView = TextView(this).apply {
                text = "VETO LOCKDOWN ACTIVE"
                setTextColor(Color.WHITE)
                textSize = 15f
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                letterSpacing = 0.15f
                gravity = Gravity.CENTER
            }
            val titleParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(6)
            }
            card.addView(titleView, titleParams)

            // Message "Focus Session in Progress"
            val msgView = TextView(this).apply {
                text = "This application is restricted during your focus lockdown."
                setTextColor(Color.parseColor("#B3FFFFFF")) // 70% opacity white
                textSize = 13f
                typeface = Typeface.create("sans-serif", Typeface.NORMAL)
                gravity = Gravity.CENTER
            }
            val msgParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(6)
            }
            card.addView(msgView, msgParams)

            // Detail line
            val detailView = TextView(this).apply {
                text = "Reason: $target"
                setTextColor(Color.parseColor("#80FF6B6B")) // 50% opacity coral
                textSize = 11f
                typeface = Typeface.create("sans-serif", Typeface.ITALIC)
                gravity = Gravity.CENTER
            }
            card.addView(detailView)

            // Add view to window manager
            try {
                wm.addView(container, params)
                overlayView = container

                // Auto-dismiss in 3 seconds
                handler.postDelayed({
                    removeOverlay(container)
                }, 3000L)
            } catch (e: Exception) {
                Log.e(TAG, "Error displaying overlay: ${e.message}")
            }
        }
    }

    private fun removeOverlay(view: View) {
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        try {
            wm.removeView(view)
            if (overlayView == view) {
                overlayView = null
            }
        } catch (e: Exception) {
            // Ignore (already removed or context destroyed)
        }
    }

    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }

    class AppLimitRule(
        val packageName: String,
        val limitMinutes: Int,
        val isActive: Boolean
    )

    private fun isDirectivesEnabled(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getBoolean("flutter.system_directives_enabled", true)
    }

    private fun isWebsiteBlockingEnabled(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getBoolean("flutter.block_websites_enabled", false)
    }

    private fun isStrictModeEnabled(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getBoolean("flutter.strict_mode_enabled", false)
    }

    private fun getBlockedWebsites(): List<String> {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("flutter.blocked_websites", null) ?: return emptyList()
        return try {
            val arr = org.json.JSONArray(jsonStr)
            val list = mutableListOf<String>()
            for (i in 0 until arr.length()) {
                list.add(arr.getString(i))
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun isBrowserApp(packageName: String): Boolean {
        return packageName == "com.android.chrome" ||
               packageName == "org.mozilla.firefox" ||
               packageName == "com.sec.android.app.sbrowser" ||
               packageName == "com.opera.browser" ||
               packageName == "com.microsoft.emmx" ||
               packageName == "com.android.browser"
    }

    private fun getAppUsageMinutesToday(context: Context, packageName: String): Long {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
        val calendar = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, 0)
            set(java.util.Calendar.MINUTE, 0)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        val stats = usm.queryUsageStats(android.app.usage.UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        if (stats != null) {
            for (usageStats in stats) {
                if (usageStats.packageName == packageName) {
                    return usageStats.totalTimeInForeground / (1000 * 60)
                }
            }
        }
        return 0L
    }

    private fun getAppLimits(): List<AppLimitRule> {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("flutter.veto_app_limits", null) ?: return emptyList()
        return try {
            val arr = org.json.JSONArray(jsonStr)
            val list = mutableListOf<AppLimitRule>()
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val packName = obj.getString("packageName")
                val limit = obj.getInt("dailyLimitMinutes")
                val active = obj.optBoolean("isActive", true)
                list.add(AppLimitRule(packName, limit, active))
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * Reload rules from SharedPreferences into memory cache.
     * Called on service start and when broadcast received from MainActivity.
     */
    private fun reloadRules() {
        cachedRules = rulesEngine.getActiveRules()
    }

    /**
     * Recycle accessibility node info objects to prevent memory leaks.
     */
    private fun recycleNodes(nodes: List<AccessibilityNodeInfo>?) {
        nodes?.forEach {
            try {
                @Suppress("DEPRECATION")
                it.recycle()
            } catch (_: Exception) {
                // Already recycled — ignore
            }
        }
    }

    override fun onInterrupt() {
        pendingRunnable?.let { handler.removeCallbacks(it) }
    }

    override fun onDestroy() {
        super.onDestroy()
        pendingRunnable?.let { handler.removeCallbacks(it) }
        try {
            unregisterReceiver(rulesReloadReceiver)
        } catch (_: Exception) {
            // Receiver wasn't registered — ignore
        }
    }
}
