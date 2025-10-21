import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flyff_launch/providers/browser_provider.dart';
import 'package:flyff_launch/providers/click_provider.dart';
import 'package:flyff_launch/views/widgets/browser_content_widget.dart';
import 'package:flyff_launch/views/widgets/recording_overlay_widget.dart';
import 'package:flyff_launch/views/widgets/floating_action_button_widget.dart';
import 'package:flyff_launch/controllers/browser_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 创建一个缩放比例的Provider
final zoomScaleProvider = StateProvider<double>((ref) => 0.8);

// 保存缩放比例到SharedPreferences
Future<void> saveZoomScale(double scale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('zoom_scale', scale);
}

// 从SharedPreferences加载缩放比例
Future<double> loadZoomScale() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('zoom_scale') ?? 0.8; // 默认值为0.8
}

class BrowserPage extends HookConsumerWidget {
  const BrowserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final accessibilityController = ref.read(accessibilityControllerProvider);
    // final accessibilityNotifier = ref.read(accessibilityEnabledProvider.notifier);
    final browserState = ref.watch(browserTabsProvider);
    final browserNotifier = ref.read(browserTabsProvider.notifier);
    final browserController = ref.read(browserControllerProvider);

    // 检查无障碍服务状态并定期更新
    // useEffect(() {
    //   // 立即检查一次
    //   Future.microtask(() async {
    //     final isEnabled = await accessibilityController.isAccessibilityServiceEnabled();
    //     accessibilityNotifier.state = isEnabled;
    //   });
    //
    //   // 设置定时器定期检查无障碍服务状态
    //   final timer = Timer.periodic(const Duration(seconds: 2), (_) async {
    //     final isEnabled = await accessibilityController.isAccessibilityServiceEnabled();
    //     if (accessibilityNotifier.state != isEnabled) {
    //       accessibilityNotifier.state = isEnabled;
    //     }
    //   });
    //
    //   // 清理函数
    //   return () {
    //     timer.cancel();
    //   };
    // }, const []);


    // 在构建时加载保存的缩放比例
    useEffect(() {
      Future.microtask(() async {
        final savedScale = await loadZoomScale();
        ref.read(zoomScaleProvider.notifier).state = savedScale;
        _applyZoomScale(ref);
      });
      return null;
    }, const []);


    return DefaultTabController(
      length: browserState.tabs.length,
      initialIndex: browserState.currentIndex.clamp(0, browserState.tabs.length - 1),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.grey[100],
          elevation: 1,
          toolbarHeight: 48,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Expanded(
                child: TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.deepPurple,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.black87,
                  indicatorWeight: 3,
                  onTap: (index) {
                    browserNotifier.switchTab(index);
                  },
                  tabs: browserState.tabs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tab = entry.value;
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              tab.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (browserState.tabs.length > 1)
                            GestureDetector(
                              onTap: () async {
                                final shouldClose = await browserController.showCloseTabDialog(context);
                                if (shouldClose == true) {
                                  browserNotifier.closeTab(index);
                                }
                              },
                              child: const Icon(Icons.close, size: 16),
                            ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () async {
                              final shouldReload = await browserController.showReloadTabDialog(context);
                              if (shouldReload == true) {
                                browserState.tabs[index].controller?.reload();
                              }
                            },
                            child: const Icon(Icons.refresh, size: 16),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => browserNotifier.addNewTab(),
                color: Colors.deepPurple,
              ),

              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () => _showZoomDialog(context, ref),
                color: Colors.deepPurple,
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              physics: const NeverScrollableScrollPhysics(), // 禁用左右滑动切换tab页
              children: browserState.tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                return BrowserContentWidget(
                  key: ValueKey(tab.tabId),
                  tabIndex: index,
                );
              }).toList(),
            ),
            // const RecordingOverlayWidget(),
            // const FloatingActionButtonWidget(),
          ],
        ),
      ),
    );
  }


  // 显示缩放对话框
  void _showZoomDialog(BuildContext context, WidgetRef ref) {
    final currentScale = ref.read(zoomScaleProvider);
    double selectedScale = currentScale;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置页面缩放'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('当前缩放比例: ${(selectedScale * 100).toStringAsFixed(0)}%'),
                Slider(
                  value: selectedScale,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  label: '${(selectedScale * 100).toStringAsFixed(0)}%',
                  onChanged: (value) {
                    setState(() {
                      selectedScale = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(zoomScaleProvider.notifier).state = selectedScale;
              _applyZoomScale(ref);
              // 保存缩放比例到本地存储
              saveZoomScale(selectedScale);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 应用缩放比例到所有标签页
  void _applyZoomScale(WidgetRef ref) {
    final browserState = ref.read(browserTabsProvider);
    final scale = ref.read(zoomScaleProvider);

    for (var i = 0; i < browserState.tabs.length; i++) {
      final controller = browserState.tabs[i].controller;
      if (controller != null) {
        controller.evaluateJavascript(source: """
          var meta = document.querySelector('meta[name=viewport]');
          if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            document.head.appendChild(meta);
          }
          meta.content = 'width=device-width, initial-scale=$scale, maximum-scale=$scale, minimum-scale=$scale, user-scalable=no';
        """);
      }
    }
  }
}