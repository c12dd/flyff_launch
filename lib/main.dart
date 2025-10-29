import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flyff_launch/views/browser_page.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flyff_launch/utils/webview_prewarm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 设置状态栏透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // // 强制横屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Android: 启用 Service Worker 支持（若可用）
  await enableServiceWorkersIfAvailable();

  // 预热：在应用启动时用无头 WebView 打开目标站点一次，
  // 让 SW/缓存初始化，后续正式 WebView 打开会更快
  // 注意：请替换为你的实际游戏入口 URL
  await prewarmWebViewCache(Uri.parse('https://universe.flyff.com/play'));

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flyff Launch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const BrowserPage(),
    );
  }
}
