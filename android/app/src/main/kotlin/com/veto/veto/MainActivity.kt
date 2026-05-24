package com.veto.veto

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity — FlutterActivity with MethodChannel host for Veto.
 *
 * Handles:
 * - setDeepBlockRule: writes rule to SharedPreferences, broadcasts to AccessibilityService
 * - getActiveRules: reads rules from SharedPreferences
 * - isAccessibilityServiceEnabled: checks Settings.Secure
 * - openAccessibilitySettings: launches system accessibility settings
 * - getTodayUsageMinutes: reads from UsageStatsManager (stub for now)
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.veto.app/bridge"
    }

    private lateinit var rulesEngine: VetoRulesEngine

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        rulesEngine = VetoRulesEngine(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "setDeepBlockRule" -> {
                        try {
                            val packageName = call.argument<String>("packageName")
                                ?: return@setMethodCallHandler result.error(
                                    "INVALID_ARG", "packageName is required", null
                                )
                            val targets = call.argument<List<String>>("targets")
                                ?: return@setMethodCallHandler result.error(
                                    "INVALID_ARG", "targets is required", null
                                )
                            val enabled = call.argument<Boolean>("enabled")
                                ?: return@setMethodCallHandler result.error(
                                    "INVALID_ARG", "enabled is required", null
                                )

                            // Write to SharedPreferences
                            rulesEngine.setRule(packageName, targets, enabled)

                            // Broadcast to AccessibilityService to reload rules
                            val intent = Intent(VetoAccessibilityService.ACTION_RELOAD_RULES)
                            intent.setPackage(packageName())
                            sendBroadcast(intent)

                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SET_RULE_FAILED", e.message, null)
                        }
                    }

                    "getActiveRules" -> {
                        try {
                            val json = rulesEngine.getActiveRulesJson()
                            result.success(json)
                        } catch (e: Exception) {
                            result.error("GET_RULES_FAILED", e.message, null)
                        }
                    }

                    "isAccessibilityServiceEnabled" -> {
                        try {
                            val enabled = isAccessibilityServiceActive()
                            result.success(enabled)
                        } catch (e: Exception) {
                            result.error("CHECK_FAILED", e.message, null)
                        }
                    }

                    "openAccessibilitySettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_FAILED", e.message, null)
                        }
                    }

                    "setLockdownActive" -> {
                        try {
                            val active = call.argument<Boolean>("active") ?: false
                            rulesEngine.setLockdownActive(active)
                            
                            // Broadcast to reload service state
                            val intent = Intent(VetoAccessibilityService.ACTION_RELOAD_RULES)
                            intent.setPackage(packageName())
                            sendBroadcast(intent)
                            
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LOCKDOWN_STATE_FAILED", e.message, null)
                        }
                    }

                    "getTodayUsageMinutes" -> {
                        // TODO: Implement UsageStatsManager integration
                        // For now, return mock data matching the UI
                        result.success(179) // 2h 59m
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Check if VetoAccessibilityService is currently enabled in system settings.
     * Parses Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES.
     */
    private fun isAccessibilityServiceActive(): Boolean {
        val serviceId = "${packageName}/${VetoAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.split(':').any { it.equals(serviceId, ignoreCase = true) }
    }

    /**
     * Helper to get the application package name.
     */
    private fun packageName(): String = applicationContext.packageName
}
