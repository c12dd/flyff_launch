import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flyff_launch/providers/browser_provider.dart';
import 'package:flyff_launch/providers/click_provider.dart';
import 'package:flyff_launch/views/widgets/tab_bar_widget.dart';
import 'package:flyff_launch/views/widgets/browser_content_widget.dart';
import 'package:flyff_launch/views/widgets/recording_overlay_widget.dart';
import 'package:flyff_launch/views/widgets/floating_action_button_widget.dart';

class BrowserPage extends HookConsumerWidget {
  const BrowserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityController = ref.read(accessibilityControllerProvider);
    final accessibilityNotifier = ref.read(accessibilityEnabledProvider.notifier);

    // 检查无障碍服务状态并定期更新
    useEffect(() {
      // 立即检查一次
      Future.microtask(() async {
        final isEnabled = await accessibilityController.isAccessibilityServiceEnabled();
        accessibilityNotifier.state = isEnabled;
      });
      
      // 设置定时器定期检查无障碍服务状态
      final timer = Timer.periodic(const Duration(seconds: 2), (_) async {
        final isEnabled = await accessibilityController.isAccessibilityServiceEnabled();
        if (accessibilityNotifier.state != isEnabled) {
          accessibilityNotifier.state = isEnabled;
        }
      });
      
      // 清理函数
      return () {
        timer.cancel();
      };
    }, const []);


    // 强制横屏
    useEffect(() {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      };
    }, const []);

    return const Scaffold(
      body: Stack(
        children: [
          // 主内容区域，不使用SafeArea以确保内容覆盖整个屏幕
          Column(
            children: [
              // 标签栏
              TabBarWidget(),
              
              // 浏览器内容区域
              BrowserContentWidget(),
            ],
          ),
          
          // 录制覆盖层
          // RecordingOverlayWidget(),
          
          // 悬浮按钮
          // FloatingActionButtonWidget(),
        ],
      ),
      // 使用Stack来叠加录制覆盖层和悬浮按钮
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: null,
      extendBodyBehindAppBar: true,
      primary: true,
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      persistentFooterButtons: null,
      drawer: null,
      endDrawer: null,
      drawerScrimColor: null,
      drawerEdgeDragWidth: null,
      appBar: null,
      // 使用Stack来叠加录制覆盖层和悬浮按钮
      floatingActionButton: SizedBox.shrink(),
      // 使用Stack来叠加录制覆盖层和悬浮按钮
      bottomSheet: null,
      backgroundColor: Colors.white,
      // 使用Stack来叠加录制覆盖层和悬浮按钮
      onDrawerChanged: null,
      onEndDrawerChanged: null,
      restorationId: null,
      // 使用Stack来叠加录制覆盖层和悬浮按钮
      drawerDragStartBehavior: DragStartBehavior.start,
    );
  }
}