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

    // Navigator.push(context, MaterialPageRoute(builder: (context) => const BrowserPage()));
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
}