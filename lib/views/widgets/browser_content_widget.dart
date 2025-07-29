import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flyff_launch/providers/browser_provider.dart';
import 'package:collection/collection.dart';

class BrowserContentWidget extends HookConsumerWidget {
  const BrowserContentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserState = ref.watch(browserTabsProvider);
    final browserNotifier = ref.read(browserTabsProvider.notifier);
    
    // 使用Hook保存WebView实例，避免重建
    final webViewsRef = useRef<Map<String, Widget>>({});
    
    // 为每个标签页创建或获取WebView
    for (final tab in browserState.tabs) {
      if (!webViewsRef.value.containsKey(tab.tabId)) {
        webViewsRef.value[tab.tabId] = InAppWebView(
          key: ValueKey(tab.tabId),
          initialUrlRequest: URLRequest(url: WebUri.uri(tab.initialUrl)),
          initialSettings: tab.options,
          onTitleChanged: (controller, title) {
            if (title != null) {
              final currentIndex = browserState.tabs.indexWhere((t) => t.tabId == tab.tabId);
              if (currentIndex != -1) {
                browserNotifier.updateTabTitle(currentIndex, title);
              }
            }
          },
          onWebViewCreated: (controller) {
            final currentIndex = browserState.tabs.indexWhere((t) => t.tabId == tab.tabId);
            if (currentIndex != -1) {
              browserNotifier.updateTabController(currentIndex, controller);
            }
          },
          onLoadStart: (controller, url) {
            // 页面开始加载时的优化
            debugPrint('开始加载: $url');
          },
          onLoadStop: (controller, url) {
            // 页面加载完成后的优化
            debugPrint('加载完成: $url');
          },
          onProgressChanged: (controller, progress) {
            // 可以在这里显示加载进度
            debugPrint('加载进度: $progress%');
          },
          onReceivedError: (controller, request, error) {
            debugPrint('加载错误: ${error.description}');
          },
        );
      }
    }
    
    // 清理已关闭的标签页
    webViewsRef.value.removeWhere((tabId, _) => 
      !browserState.tabs.any((tab) => tab.tabId == tabId));
    
    // 获取当前标签页
    final currentTab = browserState.currentIndex < browserState.tabs.length
        ? browserState.tabs[browserState.currentIndex]
        : null;
    
    return Expanded(
      child: Stack(
        children: browserState.tabs.map((tab) {
          // 确保所有WebView都已创建
          if (!webViewsRef.value.containsKey(tab.tabId)) {
            return const SizedBox.shrink();
          }
          
          // 只显示当前选中的标签页，其他标签页隐藏但保持状态
          return Offstage(
            offstage: tab.tabId != (currentTab?.tabId ?? ''),
            child: webViewsRef.value[tab.tabId]!,
          );
        }).toList(),
      ),
    );
  }
}