import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessibilityController {
  static const platform = MethodChannel('com.c12dd.flyff_launch/accessibility');

  // 检查无障碍服务是否启用
  Future<bool> checkAccessibility() async {
    try {
      final bool enabled = await platform.invokeMethod('isAccessibilityEnabled');
      return enabled;
    } on PlatformException catch (e) {
      debugPrint("Failed to check accessibility: '${e.message}'.");
      return false;
    }
  }
  
  // 检查无障碍服务是否启用
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool enabled = await platform.invokeMethod('isAccessibilityEnabled');
      return enabled;
    } on PlatformException catch (e) {
      debugPrint("Failed to check accessibility: '${e.message}'.");
      return false;
    }
  }

  // 请求无障碍权限
  Future<void> requestAccessibility() async {
    try {
      await platform.invokeMethod('requestAccessibility');
    } on PlatformException catch (e) {
      debugPrint("Failed to request accessibility: '${e.message}'.");
    }
  }

  // 执行点击操作
  Future<void> performClick(double x, double y) async {
    try {
      // 在横屏模式下，需要转换坐标
      // Flutter的(x,y)需要转换为Android原生的(x,y)
      await platform.invokeMethod('performClick', {'x': x, 'y': y});
    } on PlatformException catch (e) {
      debugPrint("Failed to perform click: '${e.message}'.");
    }
  }

  // 显示无障碍权限对话框
  void showAccessibilityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要无障碍权限'),
        content: const Text('此功能需要开启无障碍服务来模拟点击。请在设置中为本应用开启权限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              requestAccessibility();
              Navigator.of(context).pop();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}