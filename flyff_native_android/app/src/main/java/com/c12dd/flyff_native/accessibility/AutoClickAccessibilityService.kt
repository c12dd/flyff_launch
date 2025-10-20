package com.c12dd.flyff_native.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class AutoClickAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "AutoClickService"
        var instance: AutoClickAccessibilityService? = null
            private set
        
        fun isServiceEnabled(): Boolean {
            return instance != null
        }
        
        fun performClick(x: Float, y: Float): Boolean {
            return instance?.executeClick(x, y) ?: false
        }
        
        fun performClickSequence(points: List<Pair<Float, Float>>, delayMs: Long = 100): Boolean {
            return instance?.executeClickSequence(points, delayMs) ?: false
        }
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "无障碍服务已连接")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "无障碍服务已断开")
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // 不需要处理特定的无障碍事件
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "无障碍服务被中断")
    }
    
    private fun executeClick(x: Float, y: Float): Boolean {
        return try {
            val path = Path().apply {
                moveTo(x, y)
            }
            
            val gesture = GestureDescription.Builder()
                .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
                .build()
            
            val result = dispatchGesture(gesture, object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    super.onCompleted(gestureDescription)
                    Log.d(TAG, "点击完成: ($x, $y)")
                }
                
                override fun onCancelled(gestureDescription: GestureDescription?) {
                    super.onCancelled(gestureDescription)
                    Log.w(TAG, "点击被取消: ($x, $y)")
                }
            }, null)
            
            Log.d(TAG, "执行点击: ($x, $y), 结果: $result")
            result
        } catch (e: Exception) {
            Log.e(TAG, "执行点击失败: ($x, $y)", e)
            false
        }
    }
    
    private fun executeClickSequence(points: List<Pair<Float, Float>>, delayMs: Long): Boolean {
        if (points.isEmpty()) return false
        
        return try {
            val gestureBuilder = GestureDescription.Builder()
            var startTime = 0L
            
            points.forEach { (x, y) ->
                val path = Path().apply {
                    moveTo(x, y)
                }
                
                gestureBuilder.addStroke(
                    GestureDescription.StrokeDescription(path, startTime, 100)
                )
                
                startTime += delayMs
            }
            
            val gesture = gestureBuilder.build()
            
            val result = dispatchGesture(gesture, object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    super.onCompleted(gestureDescription)
                    Log.d(TAG, "点击序列完成，共 ${points.size} 个点")
                }
                
                override fun onCancelled(gestureDescription: GestureDescription?) {
                    super.onCancelled(gestureDescription)
                    Log.w(TAG, "点击序列被取消")
                }
            }, null)
            
            Log.d(TAG, "执行点击序列，共 ${points.size} 个点，结果: $result")
            result
        } catch (e: Exception) {
            Log.e(TAG, "执行点击序列失败", e)
            false
        }
    }
}