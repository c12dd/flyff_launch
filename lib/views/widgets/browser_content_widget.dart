import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flyff_launch/providers/browser_provider.dart';

class BrowserContentWidget extends HookConsumerWidget {
  final int? tabIndex;
  
  const BrowserContentWidget({super.key, this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserState = ref.watch(browserTabsProvider);
    final browserNotifier = ref.read(browserTabsProvider.notifier);
    
    // 获取当前标签页索引
    final currentIndex = tabIndex ?? browserState.currentIndex;
    
    // 确保索引有效
    if (currentIndex >= browserState.tabs.length || currentIndex < 0) {
      return const Center(
        child: Text('标签页不存在'),
      );
    }
    
    final currentTab = browserState.tabs[currentIndex];
    
    return _WebViewContainer(
      tab: currentTab,
      browserNotifier: browserNotifier,
    );
  }
}

class _WebViewContainer extends StatefulWidget {
  final dynamic tab;
  final dynamic browserNotifier;
  
  const _WebViewContainer({
    required this.tab,
    required this.browserNotifier,
  });
  
  @override
  State<_WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<_WebViewContainer> 
    with AutomaticKeepAliveClientMixin {
  
  InAppWebViewController? _controller;
  
  @override
  bool get wantKeepAlive => true; // 保持状态不被销毁
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以保持状态
    
    return InAppWebView(
      key: ValueKey(widget.tab.tabId),
      initialUrlRequest: URLRequest(url: WebUri.uri(widget.tab.initialUrl)),
      initialSettings: widget.tab.options,
      onWebViewCreated: (controller) {
        _controller = controller;
        final currentIndex = widget.browserNotifier.state.tabs
            .indexWhere((t) => t.tabId == widget.tab.tabId);
        if (currentIndex != -1) {
          widget.browserNotifier.updateTabController(currentIndex, controller);
        }
      },
      onTitleChanged: (controller, title) {
        if (title != null) {
          final currentIndex = widget.browserNotifier.state.tabs
              .indexWhere((t) => t.tabId == widget.tab.tabId);
          if (currentIndex != -1) {
            widget.browserNotifier.updateTabTitle(currentIndex, title);
          }
        }
      },
      onLoadStart: (controller, url) {
        debugPrint('开始加载: $url');
      },
      onLoadStop: (controller, url) async {
        debugPrint('加载完成: $url');
        await controller.evaluateJavascript(source: """
           var meta = document.querySelector('meta[name=viewport]');
           if (!meta) {
              meta = document.createElement('meta');
              meta.name = 'viewport';
              document.head.appendChild(meta);
           }
           meta.content = 'width=device-width, initial-scale=0.8, maximum-scale=0.8, minimum-scale=0.8, user-scalable=no';
  """);
      },
      onProgressChanged: (controller, progress) {
        debugPrint('加载进度: $progress%');
      },
      onReceivedError: (controller, request, error) {
        debugPrint('加载错误: ${error.description}');
      },
    );
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}