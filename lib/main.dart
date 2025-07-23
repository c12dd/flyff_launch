import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class BrowserTab {
  String title;
  InAppWebViewController? controller;
  final String tabId;
  final InAppWebViewSettings options;
  final Uri initialUrl;

  BrowserTab({
    required this.title,
    this.controller,
    required this.tabId,
    required this.initialUrl,
    required this.options,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '横屏浏览器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BrowserHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BrowserHomePage extends StatefulWidget {
  const BrowserHomePage({super.key});

  @override
  State<BrowserHomePage> createState() => _BrowserHomePageState();
}

class _BrowserHomePageState extends State<BrowserHomePage> {
  static const platform = MethodChannel('com.c12dd.flyff_launch/accessibility');

  List<BrowserTab> tabs = [];
  int currentIndex = 0;
  int tabCount = 1;

  List<Offset> clickPoints = [];
  bool isAutoClicking = false;
  Timer? autoClickTimer;
  bool isAccessibilityEnabled = true;
  bool isRecording = false; // 新增：录制状态

  @override
  void initState() {
    super.initState();
    _checkAccessibility();
    _addNewTab();
    _loadClickPoints();
  }

  Future<void> _checkAccessibility() async {
    try {
      final bool enabled = await platform.invokeMethod('isAccessibilityEnabled');
      setState(() {
        isAccessibilityEnabled = enabled;
      });
    } on PlatformException catch (e) {
      print("Failed to check accessibility: '${e.message}'.");
    }
  }

  Future<void> _requestAccessibility() async {
    try {
      await platform.invokeMethod('requestAccessibility');
    } on PlatformException catch (e) {
      print("Failed to request accessibility: '${e.message}'.");
    }
  }

  Future<void> _performClick(double x, double y) async {
    try {
      // 在横屏模式下，需要转换坐标
      // Flutter的(x,y)需要转换为Android原生的(x,y)
      // 这通常意味着x和y的互换，以及基于屏幕尺寸的偏移
      // 一个简化的假设是：我们总是处于一个方向的横屏
      // 注意：这需要根据具体的横屏方向微调
      await platform.invokeMethod('performClick', {'x': x, 'y': y});
    } on PlatformException catch (e) {
      print("Failed to perform click: '${e.message}'.");
    }
  }

  String _generateTabId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${tabs.length + 1}';
  }

  void _addNewTab() {
    final tabId = _generateTabId();
    final options = InAppWebViewSettings(
      javaScriptEnabled: true,
      transparentBackground: true,
    );

    setState(() {
      tabs.add(BrowserTab(
        title: '窗口$tabCount',
        tabId: tabId,
        initialUrl: Uri.parse('https://universe.flyff.com/play'),
        // initialUrl: Uri.parse('https://www.baidu.com'),
        options: options,
      ));
      currentIndex = tabs.length - 1;
      tabCount++;
    });
  }

  Future<void> _closeTab(int index) async {
    if (tabs.length == 1) return;
    setState(() {
      tabs.removeAt(index);
      if (currentIndex >= tabs.length) {
        currentIndex = tabs.length - 1;
      }
    });
  }

  void _onTabSwitch(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> _saveClickPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final points = clickPoints.map((e) => {'dx': e.dx, 'dy': e.dy}).toList();
    prefs.setString('click_points', json.encode(points));
  }

  Future<void> _loadClickPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('click_points');
    if (str != null && str.isNotEmpty) {
      try {
        final List list = json.decode(str);
        setState(() {
          clickPoints = list.map((e) => Offset((e['dx'] as num).toDouble(), (e['dy'] as num).toDouble())).toList();
        });
      } catch (e) {
        // Handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkAccessibility();
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: Stack(
                  children: [
                    IndexedStack(
                      index: currentIndex,
                      children: tabs.mapIndexed((index,tab) {
                        return InAppWebView(
                          key: ValueKey(tab.tabId),
                          initialUrlRequest: URLRequest(url: WebUri.uri(tab.initialUrl)),
                          initialSettings: tab.options,
                          onTitleChanged: (controller, title) {
                            if (title != null) {
                              setState(() {
                                tabs[index].title = title;
                              });
                            }

                          },
                          onWebViewCreated: (controller) {
                            tab.controller = controller;
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isRecording) _buildRecordingOverlay(),
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length + 1,
              itemBuilder: (context, index) {
                if (index == tabs.length) {
                  return IconButton(icon: const Icon(Icons.add), onPressed: _addNewTab);
                }
                final isSelected = index == currentIndex;
                return GestureDetector(
                  onTap: () => _onTabSwitch(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: Colors.deepPurple, width: 2) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          tabs[index].title,
                          style: TextStyle(
                            color: isSelected ? Colors.deepPurple : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (tabs.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              final shouldClose = await showDialog<bool>(
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
                              if (shouldClose == true) {
                                _closeTab(index);
                              }
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            final shouldReload = await showDialog<bool>(
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
                            if (shouldReload == true) {
                              tabs[index].controller?.reload();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          // 直接用物理坐标（以物理屏幕左上角为原点）
          final Offset physicalPoint = details.globalPosition;
          setState(() {
            clickPoints.add(physicalPoint);
          });
        },
        child: Container(
          color: Colors.grey.withOpacity(0.5),
          child: Stack(
            children: clickPoints.map((point) {
              return Positioned(
                left: point.dx - 12,
                top: point.dy - 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      right: 32,
      bottom: 32,
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            isRecording = !isRecording;
            if (isRecording) {
              clickPoints.clear();
              if (isAutoClicking) {
                isAutoClicking = false;
                autoClickTimer?.cancel();
              }
            } else {
              _saveClickPoints();
            }
          });
        },
        onTap: () {
          if (isRecording) return;
          if (isAutoClicking) {
            setState(() {
              isAutoClicking = false;
              autoClickTimer?.cancel();
            });
            return;
          }
          if (!isAccessibilityEnabled || clickPoints.isEmpty) {
            if (!isAccessibilityEnabled) {
              _showAccessibilityDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('没有可点击的坐标。请长按按钮进入录制模式。'),
              ));
            }
            return;
          }
          setState(() {
            isAutoClicking = true;
          });
          // 获取物理屏幕宽高（以物理像素为单位，除以像素比得到dp）
          final double screenW = ui.window.physicalSize.width / ui.window.devicePixelRatio;
          final double screenH = ui.window.physicalSize.height / ui.window.devicePixelRatio;
          final double dpr = ui.window.devicePixelRatio;
          int idx = 0;
          autoClickTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) async {
            if (!mounted || !isAutoClicking) {
              timer.cancel();
              return;
            }
            final pt = clickPoints[idx];
            double nativeX = pt.dx * dpr;
            double nativeY = pt.dy * dpr;
            // 边界保护
            nativeX = nativeX.clamp(0.0, screenW * dpr - 1);
            nativeY = nativeY.clamp(0.0, screenH * dpr - 1);
            await _performClick(nativeX, nativeY);
            idx = (idx + 1) % clickPoints.length;
          });
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isRecording ? Colors.orange : (isAccessibilityEnabled ? Colors.blue : Colors.grey),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Icon(
            isRecording ? Icons.edit : (isAutoClicking ? Icons.pause : Icons.touch_app),
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  void _showAccessibilityDialog() {
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
              _requestAccessibility();
              Navigator.of(context).pop();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}
