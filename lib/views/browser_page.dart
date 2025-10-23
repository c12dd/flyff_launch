import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flyff_launch/providers/browser_provider.dart';
import 'package:flyff_launch/views/widgets/browser_content_widget.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    final browserState = ref.watch(browserTabsProvider);
    final browserNotifier = ref.read(browserTabsProvider.notifier);
    final browserController = ref.read(browserControllerProvider);


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
      animationDuration: Duration.zero,
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: () async {
                await _sendMsg(ref, "1");
              },
              child: const Icon(Icons.looks_one),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: () async {
                await _sendMsg(ref, "2");
              },
              child: const Icon(Icons.looks_two),
            ),
          ],
        ),
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
                  // tabAlignment: TabAlignment.start,
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
        body: TabBarView(
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

  Future<void> _sendMsg(WidgetRef ref,String key) async{
    final browserState = ref.read(browserTabsProvider);

    for (var i = 0; i < browserState.tabs.length; i++) {
      final controller = browserState.tabs[i].controller;
      if (controller != null) {
        final entry = keyboardMap[key];
        if (entry == null) {
          print("⚠️ 不支持的按键: $key");
          return;
        }
        final code = entry['code'];
        final keyCode = entry['keyCode'];

        await controller.evaluateJavascript(source: """
    (function() {
      
      input = document.querySelector('Canvas')
      var down = new KeyboardEvent('keydown', { key: '$key', code: '$code', keyCode: $keyCode, bubbles: true });
      var press = new KeyboardEvent('keypress', { key: '$key', code: '$code', keyCode: $keyCode, bubbles: true });
      var up = new KeyboardEvent('keyup', { key: '$key', code: '$code', keyCode: $keyCode, bubbles: true });
      input.dispatchEvent(down);
      input.dispatchEvent(press);
      input.dispatchEvent(up);
    })();
  """);
      }
    }
  }
}



const Map<String, Map<String, dynamic>> keyboardMap = {
  // 字母键
  'a': {'code': 'KeyA', 'keyCode': 65},
  'b': {'code': 'KeyB', 'keyCode': 66},
  'c': {'code': 'KeyC', 'keyCode': 67},
  'd': {'code': 'KeyD', 'keyCode': 68},
  'e': {'code': 'KeyE', 'keyCode': 69},
  'f': {'code': 'KeyF', 'keyCode': 70},
  'g': {'code': 'KeyG', 'keyCode': 71},
  'h': {'code': 'KeyH', 'keyCode': 72},
  'i': {'code': 'KeyI', 'keyCode': 73},
  'j': {'code': 'KeyJ', 'keyCode': 74},
  'k': {'code': 'KeyK', 'keyCode': 75},
  'l': {'code': 'KeyL', 'keyCode': 76},
  'm': {'code': 'KeyM', 'keyCode': 77},
  'n': {'code': 'KeyN', 'keyCode': 78},
  'o': {'code': 'KeyO', 'keyCode': 79},
  'p': {'code': 'KeyP', 'keyCode': 80},
  'q': {'code': 'KeyQ', 'keyCode': 81},
  'r': {'code': 'KeyR', 'keyCode': 82},
  's': {'code': 'KeyS', 'keyCode': 83},
  't': {'code': 'KeyT', 'keyCode': 84},
  'u': {'code': 'KeyU', 'keyCode': 85},
  'v': {'code': 'KeyV', 'keyCode': 86},
  'w': {'code': 'KeyW', 'keyCode': 87},
  'x': {'code': 'KeyX', 'keyCode': 88},
  'y': {'code': 'KeyY', 'keyCode': 89},
  'z': {'code': 'KeyZ', 'keyCode': 90},

  // 数字键
  '0': {'code': 'Digit0', 'keyCode': 48},
  '1': {'code': 'Digit1', 'keyCode': 49},
  '2': {'code': 'Digit2', 'keyCode': 50},
  '3': {'code': 'Digit3', 'keyCode': 51},
  '4': {'code': 'Digit4', 'keyCode': 52},
  '5': {'code': 'Digit5', 'keyCode': 53},
  '6': {'code': 'Digit6', 'keyCode': 54},
  '7': {'code': 'Digit7', 'keyCode': 55},
  '8': {'code': 'Digit8', 'keyCode': 56},
  '9': {'code': 'Digit9', 'keyCode': 57},

  // 方向键与控制键
  'Enter': {'code': 'Enter', 'keyCode': 13},
  'Backspace': {'code': 'Backspace', 'keyCode': 8},
  'Space': {'code': 'Space', 'keyCode': 32},
  'ArrowUp': {'code': 'ArrowUp', 'keyCode': 38},
  'ArrowDown': {'code': 'ArrowDown', 'keyCode': 40},
  'ArrowLeft': {'code': 'ArrowLeft', 'keyCode': 37},
  'ArrowRight': {'code': 'ArrowRight', 'keyCode': 39},
  'Tab': {'code': 'Tab', 'keyCode': 9},
  'Escape': {'code': 'Escape', 'keyCode': 27},
};