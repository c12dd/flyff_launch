import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flyff_launch/models/browser_tab.dart';

class BrowserController {
  // 默认WebView设置，针对多tab场景优化
  InAppWebViewSettings get defaultSettings => InAppWebViewSettings(
    javaScriptEnabled: true,
    transparentBackground: true,
    // 性能优化设置
    hardwareAcceleration: true,
    cacheEnabled: true,
    databaseEnabled: true,
    domStorageEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    useOnRenderProcessGone: true,
    // 多tab优化设置
    clearCache: false, // 保持缓存以提升切换速度
    clearSessionCache: false,
    incognito: false, // 允许共享缓存
    // 内存优化
    minimumFontSize: 8,
    defaultFontSize: 16,
    // 网络优化·
    useShouldOverrideUrlLoading: true,
    useOnLoadResource: false, // 减少回调开销
    // 渲染优化
    disableDefaultErrorPage: false,
    supportMultipleWindows: true,
    // 滚动优化
    verticalScrollBarEnabled: true,
    horizontalScrollBarEnabled: true,
    // 缩放优化
    supportZoom: true,
    builtInZoomControls: false,
    displayZoomControls: false,
  );

  // 生成唯一的标签页ID
  String generateTabId(List<BrowserTab> tabs) {
    return '${DateTime.now().millisecondsSinceEpoch}_${tabs.length + 1}';
  }

  // 创建新的标签页
  BrowserTab createNewTab(int tabCount, {Uri? initialUrl}) {
    final tabId = '${DateTime.now().millisecondsSinceEpoch}_$tabCount';

    return BrowserTab(
      title: '窗口$tabCount',
      tabId: tabId,
      // initialUrl: initialUrl ?? Uri.parse('https://universe.flyff.com/play'),
      initialUrl: initialUrl ?? Uri.parse('https://www.baidu.com'),
      options: defaultSettings,
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