import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flyff_launch/models/browser_tab.dart';

class BrowserController {
  // 生成唯一的标签页ID
  String generateTabId(List<BrowserTab> tabs) {
    return '${DateTime.now().millisecondsSinceEpoch}_${tabs.length + 1}';
  }

  // 创建新的标签页
  BrowserTab createNewTab(int tabCount, {Uri? initialUrl}) {
    final tabId = '${DateTime.now().millisecondsSinceEpoch}_$tabCount';
    final options = InAppWebViewSettings(
      // 基础设置
      javaScriptEnabled: true,
      transparentBackground: true,
      
      // 性能优化设置
      hardwareAcceleration: true,
      cacheEnabled: true,
      clearCache: false,
      
      // 网络和加载优化
      networkAvailable: true,
      supportMultipleWindows: false,
      
      // 渲染优化
      useOnRenderProcessGone: true,
      
      // 缓存策略
      cacheMode: CacheMode.LOAD_DEFAULT,
      
      // 媒体播放优化
      mediaPlaybackRequiresUserGesture: false,
      
      // 其他性能设置
      useWideViewPort: true,
      loadWithOverviewMode: true,
      builtInZoomControls: false,
      displayZoomControls: false,
      
      // 预加载设置
      mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
    );

    return BrowserTab(
      title: '窗口$tabCount',
      tabId: tabId,
      initialUrl: initialUrl ?? Uri.parse('https://universe.flyff.com/play'),
      // initialUrl: initialUrl ?? Uri.parse('https://www.baidu.com'),
      options: options,
    );
  }

  // 显示关闭标签页确认对话框
  Future<bool?> showCloseTabDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关闭窗口'),
        content: const Text('确定要关闭此Tab窗口吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('允许'),
          ),
        ],
      ),
    );
  }

  // 显示刷新标签页确认对话框
  Future<bool?> showReloadTabDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刷新窗口'),
        content: const Text('确定要刷新此Tab窗口吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('允许'),
          ),
        ],
      ),
    );
  }
}