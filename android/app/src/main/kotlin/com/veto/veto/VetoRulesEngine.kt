package com.veto.veto

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * SharedPreferences-backed rules engine for Veto deep node blocking.
 *
 * Data format in SharedPreferences (JSON):
 * {
 *   "com.google.android.youtube": ["Shorts", "shorts_pivot_header"],
 *   "com.instagram.android": ["Reels", "reels_tab"]
 * }
 *
 * Both the Flutter UI (via MethodChannel → MainActivity) and the
 * AccessibilityService read from the same preference file.
 * SharedPreferences is process-safe with MODE_PRIVATE for same-process access.
 */
class VetoRulesEngine(private val context: Context) {

    companion object {
        private const val PREFS_NAME = "veto_rules"
        private const val KEY_DEEP_BLOCKS = "veto_deep_block_rules"
    }

    private val prefs: SharedPreferences
        get() = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Get all active deep block rules.
     * Returns a map of packageName → list of target node texts.
     */
    fun getActiveRules(): Map<String, List<String>> {
        var json = prefs.getString(KEY_DEEP_BLOCKS, null)
        if (json == null) {
            try {
                val defaults = JSONObject().apply {
                    put("com.google.android.youtube", JSONArray(listOf("Shorts", "shorts_pivot_header")))
                    put("com.instagram.android", JSONArray(listOf("Reels", "reels_tab")))
                }
                json = defaults.toString()
                prefs.edit().putString(KEY_DEEP_BLOCKS, json).apply()
            } catch (e: Exception) {
                // ignore
            }
        }
        if (json == null) return emptyMap()
        return try {
            val obj = JSONObject(json)
            val result = mutableMapOf<String, List<String>>()
            obj.keys().forEach { key ->
                val arr = obj.getJSONArray(key)
                val targets = mutableListOf<String>()
                for (i in 0 until arr.length()) {
                    targets.add(arr.getString(i))
                }
                if (targets.isNotEmpty()) {
                    result[key] = targets
                }
            }
            result
        } catch (e: Exception) {
            emptyMap()
        }
    }

    /**
     * Set or remove a deep block rule for a specific package.
     *
     * @param packageName The target app package name
     * @param targets List of node text strings to match (e.g., ["Shorts"])
     * @param enabled Whether to enable or disable this rule
     */
    fun setRule(packageName: String, targets: List<String>, enabled: Boolean) {
        val current = getActiveRulesRaw()

        if (enabled && targets.isNotEmpty()) {
            val arr = JSONArray()
            targets.forEach { arr.put(it) }
            current.put(packageName, arr)
        } else {
            current.remove(packageName)
        }

        prefs.edit()
            .putString(KEY_DEEP_BLOCKS, current.toString())
            .apply()
    }

    /**
     * Get the raw JSON string for MethodChannel return.
     */
    fun getActiveRulesJson(): String {
        return prefs.getString(KEY_DEEP_BLOCKS, "{}") ?: "{}"
    }

    /**
     * Check if any rules exist for a specific package.
     * Used by AccessibilityService for fast early-return.
     */
    fun hasRulesForPackage(packageName: String): Boolean {
        val rules = getActiveRules()
        return rules.containsKey(packageName)
    }

    /**
     * Get target texts for a specific package.
     */
    fun getTargetsForPackage(packageName: String): List<String> {
        return getActiveRules()[packageName] ?: emptyList()
    }

    fun isLockdownActive(): Boolean {
        return prefs.getBoolean("is_lockdown_active", false)
    }

    fun setLockdownActive(active: Boolean) {
        prefs.edit().putBoolean("is_lockdown_active", active).apply()
    }

    private fun getActiveRulesRaw(): JSONObject {
        val json = prefs.getString(KEY_DEEP_BLOCKS, null) ?: return JSONObject()
        return try {
            JSONObject(json)
        } catch (e: Exception) {
            JSONObject()
        }
    }
}
