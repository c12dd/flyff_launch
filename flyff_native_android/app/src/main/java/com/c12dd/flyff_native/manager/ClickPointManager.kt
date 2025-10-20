package com.c12dd.flyff_native.manager

import android.content.Context
import android.content.SharedPreferences
import android.graphics.PointF
import com.c12dd.flyff_native.accessibility.AutoClickAccessibilityService
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject

class ClickPointManager(private val context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val clickPoints = mutableListOf<PointF>()
    private var autoClickJob: Job? = null
    
    companion object {
        private const val PREFS_NAME = "click_points_prefs"
        private const val KEY_CLICK_POINTS = "click_points"
        private const val KEY_AUTO_CLICK_ENABLED = "auto_click_enabled"
        private const val KEY_CLICK_INTERVAL = "click_interval"
        
        private const val DEFAULT_CLICK_INTERVAL = 1000L // 1秒
    }
    
    init {
        loadClickPoints()
    }
    
    fun addClickPoint(x: Float, y: Float) {
        clickPoints.add(PointF(x, y))
        saveClickPoints()
    }
    
    fun removeClickPoint(index: Int) {
        if (index >= 0 && index < clickPoints.size) {
            clickPoints.removeAt(index)
            saveClickPoints()
        }
    }
    
    fun clearClickPoints() {
        clickPoints.clear()
        saveClickPoints()
    }
    
    fun getClickPoints(): List<PointF> {
        return clickPoints.toList()
    }
    
    fun startAutoClick(intervalMs: Long = getClickInterval()) {
        if (!AutoClickAccessibilityService.isServiceEnabled()) {
            return
        }
        
        stopAutoClick()
        
        autoClickJob = CoroutineScope(Dispatchers.Main).launch {
            while (isActive && clickPoints.isNotEmpty()) {
                clickPoints.forEach { point ->
                    if (isActive) {
                        AutoClickAccessibilityService.performClick(point.x, point.y)
                        delay(intervalMs)
                    }
                }
            }
        }
        
        setAutoClickEnabled(true)
    }
    
    fun stopAutoClick() {
        autoClickJob?.cancel()
        autoClickJob = null
        setAutoClickEnabled(false)
    }
    
    fun isAutoClickRunning(): Boolean {
        return autoClickJob?.isActive == true
    }
    
    fun performSingleClick(x: Float, y: Float): Boolean {
        return AutoClickAccessibilityService.performClick(x, y)
    }
    
    fun performClickSequence(delayMs: Long = 100): Boolean {
        if (clickPoints.isEmpty()) return false
        
        val points = clickPoints.map { Pair(it.x, it.y) }
        return AutoClickAccessibilityService.performClickSequence(points, delayMs)
    }
    
    private fun saveClickPoints() {
        val jsonArray = JSONArray()
        clickPoints.forEach { point ->
            val jsonObject = JSONObject().apply {
                put("x", point.x.toDouble())
                put("y", point.y.toDouble())
            }
            jsonArray.put(jsonObject)
        }
        
        prefs.edit()
            .putString(KEY_CLICK_POINTS, jsonArray.toString())
            .apply()
    }
    
    private fun loadClickPoints() {
        val jsonString = prefs.getString(KEY_CLICK_POINTS, null) ?: return
        
        try {
            val jsonArray = JSONArray(jsonString)
            clickPoints.clear()
            
            for (i in 0 until jsonArray.length()) {
                val jsonObject = jsonArray.getJSONObject(i)
                val x = jsonObject.getDouble("x").toFloat()
                val y = jsonObject.getDouble("y").toFloat()
                clickPoints.add(PointF(x, y))
            }
        } catch (e: Exception) {
            e.printStackTrace()
            clickPoints.clear()
        }
    }
    
    fun setClickInterval(intervalMs: Long) {
        prefs.edit()
            .putLong(KEY_CLICK_INTERVAL, intervalMs)
            .apply()
    }
    
    fun getClickInterval(): Long {
        return prefs.getLong(KEY_CLICK_INTERVAL, DEFAULT_CLICK_INTERVAL)
    }
    
    private fun setAutoClickEnabled(enabled: Boolean) {
        prefs.edit()
            .putBoolean(KEY_AUTO_CLICK_ENABLED, enabled)
            .apply()
    }
    
    fun isAutoClickEnabled(): Boolean {
        return prefs.getBoolean(KEY_AUTO_CLICK_ENABLED, false)
    }
}