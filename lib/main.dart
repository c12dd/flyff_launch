import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async'; // Added for Timer

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class BrowserTab {
  final String title;
  final WebViewController controller;
  final String tabId;
  BrowserTab({required this.title, required this.controller, required this.tabId});
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
  List<BrowserTab> tabs = [];
  int currentIndex = 0;
  int tabCount = 1;

  // 新增：自动点击功能相关变量
  bool isEditing = false;
  List<Offset> clickPoints = [];
  bool isAutoClicking = false;
  Timer? autoClickTimer;

  @override
  void initState() {
    super.initState();
    _addNewTab();
  }

  Future<String> _generateTabId() async {
    // 用时间戳+随机数生成唯一ID
    return '${DateTime.now().millisecondsSinceEpoch}_${tabs.length + 1}';
  }

  Future<void> _addNewTab() async {
    final tabId = await _generateTabId();
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _restoreCookies(tabId, controller);
    controller.loadRequest(Uri.parse('https://universe.flyff.com/play'));
    // controller.loadRequest(Uri.parse('https://baidu.com'));
    setState(() {
      tabs.add(BrowserTab(title: '窗口$tabCount', controller: controller, tabId: tabId));
      currentIndex = tabs.length - 1;
      tabCount++;
    });
  }

  Future<void> _closeTab(int index) async {
    if (tabs.length == 1) return; // 至少保留一个Tab
    await _saveCookies(tabs[index].tabId, tabs[index].controller);
    setState(() {
      tabs.removeAt(index);
      if (currentIndex >= tabs.length) {
        currentIndex = tabs.length - 1;
      }
    });
  }

  Future<void> _onTabSwitch(int index) async {
    // 切换前保存当前Tab的Cookie
    await _saveCookies(tabs[currentIndex].tabId, tabs[currentIndex].controller);
    // 切换后恢复目标Tab的Cookie
    await _restoreCookies(tabs[index].tabId, tabs[index].controller);
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> _saveCookies(String tabId, WebViewController controller) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = await controller.runJavaScriptReturningResult('''
        (function() {
          var cookies = document.cookie.split('; ');
          var cookieList = [];
          for (var i = 0; i < cookies.length; i++) {
            var parts = cookies[i].split('=');
            if(parts.length === 2) {
              cookieList.push({name: parts[0], value: parts[1]});
            }
          }
          return JSON.stringify(cookieList);
        })();
      ''');
      if (cookies != null && cookies is String && cookies.isNotEmpty) {
        prefs.setString('tab_cookies_$tabId', cookies);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _restoreCookies(String tabId, WebViewController controller) async {
    final prefs = await SharedPreferences.getInstance();
    final cookiesStr = prefs.getString('tab_cookies_$tabId');
    if (cookiesStr != null && cookiesStr.isNotEmpty) {
      try {
        final List cookies = json.decode(cookiesStr);
        for (var cookie in cookies) {
          if (cookie['name'] != null && cookie['value'] != null) {
            await controller.runJavaScript(
              "document.cookie='${cookie['name']}=${cookie['value']}';"
            );
          }
        }
      } catch (e) {
        // ignore
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 主体内容
            Column(
              children: [
                // 顶部Tab栏
                Container(
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
                              // 最后一个是+
                              return IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _addNewTab,
                              );
                            }
                            final isSelected = index == currentIndex;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: Colors.deepPurple, width: 2)
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      _onTabSwitch(index);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      child: Text(
                                        tabs[index].title,
                                        style: TextStyle(
                                          color: isSelected ? Colors.deepPurple : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (tabs.length > 1)
                                    GestureDetector(
                                      onTap: () async {
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
                                          await _closeTab(index);
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.only(right: 8, left: 2),
                                        child: Icon(Icons.close, size: 18, color: Colors.grey),
                                      ),
                                    ),
                                  // 刷新按钮
                                  GestureDetector(
                                    onTap: () async {
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
                                        tabs[index].controller.reload();
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 4, left: 2),
                                      child: Icon(Icons.refresh, size: 18, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
