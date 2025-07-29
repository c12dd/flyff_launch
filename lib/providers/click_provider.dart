import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flyff_launch/controllers/accessibility_controller.dart';
import 'package:flyff_launch/controllers/click_points_controller.dart';

// 无障碍控制器提供者
final accessibilityControllerProvider = Provider<AccessibilityController>((ref) {
  return AccessibilityController();
});

// 点击点控制器提供者
final clickPointsControllerProvider = Provider<ClickPointsController>((ref) {
  return ClickPointsController();
});

// 无障碍状态提供者
final accessibilityEnabledProvider = StateProvider<bool>((ref) => false);

// 点击点状态
class ClickPointsState {
  final List<Offset> points;
  final bool isRecording;
  final bool isAutoClicking;
  final Offset floatingButtonPosition;
  final Offset recordingOverlayPosition;

  ClickPointsState({
    required this.points,
    required this.isRecording,
    required this.isAutoClicking,
    required this.floatingButtonPosition,
    required this.recordingOverlayPosition,
  });

  // 创建初始状态
  factory ClickPointsState.initial() {
    return ClickPointsState(
      points: [],
      isRecording: false,
      isAutoClicking: false,
      floatingButtonPosition: const Offset(32, 32),
      recordingOverlayPosition: Offset.zero,
    );
  }

  // 创建状态的副本
  ClickPointsState copyWith({
    List<Offset>? points,
    bool? isRecording,
    bool? isAutoClicking,
    Offset? floatingButtonPosition,
    Offset? recordingOverlayPosition,
  }) {
    return ClickPointsState(
      points: points ?? this.points,
      isRecording: isRecording ?? this.isRecording,
      isAutoClicking: isAutoClicking ?? this.isAutoClicking,
      floatingButtonPosition: floatingButtonPosition ?? this.floatingButtonPosition,
      recordingOverlayPosition: recordingOverlayPosition ?? this.recordingOverlayPosition,
    );
  }
}

// 点击点状态Notifier
class ClickPointsNotifier extends StateNotifier<ClickPointsState> {
  final ClickPointsController _clickPointsController;
  final AccessibilityController _accessibilityController;
  final Ref _ref;
  Timer? _autoClickTimer;

  ClickPointsNotifier(
    this._clickPointsController,
    this._accessibilityController,
    this._ref,
  ) : super(ClickPointsState.initial()) {
    _loadClickPoints();
  }

  // 加载保存的点击点
  Future<void> _loadClickPoints() async {
    final points = await _clickPointsController.loadClickPoints();
    state = state.copyWith(points: points);
  }

  // 保存点击点
  Future<void> saveClickPoints() async {
    await _clickPointsController.saveClickPoints(state.points);
  }

  // 添加点击点
  void addClickPoint(Offset point) {
    final newPoints = [...state.points, point];
    state = state.copyWith(points: newPoints);
  }

  // 清除所有点击点
  void clearClickPoints() {
    state = state.copyWith(points: []);
  }

  // 切换录制模式
  void toggleRecording() {
    final newIsRecording = !state.isRecording;
    if (newIsRecording) {
      clearClickPoints();
      if (state.isAutoClicking) {
        stopAutoClicking();
      }
    } else {
      saveClickPoints();
    }
    state = state.copyWith(isRecording: newIsRecording);
  }

  // 开始自动点击
  void startAutoClicking(BuildContext context) async {
    if (state.isRecording) return;
    if (state.isAutoClicking) {
      stopAutoClicking();
      return;
    }

    final isAccessibilityEnabled = _ref.read(accessibilityEnabledProvider);
    if (!isAccessibilityEnabled || state.points.isEmpty) {
      if (!isAccessibilityEnabled) {
        _accessibilityController.showAccessibilityDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('没有可点击的坐标。请长按按钮进入录制模式。'),
        ));
      }
      return;
    }

    state = state.copyWith(isAutoClicking: true);

    // 获取物理屏幕宽高
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    int idx = 0;

    _autoClickTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) async {
      if (!mounted || !state.isAutoClicking) {
        timer.cancel();
        return;
      }

      final pt = state.points[idx];
      double nativeX = pt.dx * dpr;
      double nativeY = pt.dy * dpr;

      // 边界保护
      nativeX = nativeX.clamp(0.0, screenW * dpr - 1);
      nativeY = nativeY.clamp(0.0, screenH * dpr - 1);

      await _accessibilityController.performClick(nativeX, nativeY);
      idx = (idx + 1) % state.points.length;
    });
  }

  // 停止自动点击
  void stopAutoClicking() {
    _autoClickTimer?.cancel();
    state = state.copyWith(isAutoClicking: false);
  }

  // 更新悬浮按钮位置
  void updateFloatingButtonPosition(Offset delta, Size screenSize) {
    final newPosition = state.floatingButtonPosition + delta;
    // 确保按钮不会移出屏幕
    final clampedPosition = Offset(
      newPosition.dx.clamp(0, screenSize.width - 56),
      newPosition.dy.clamp(0, screenSize.height - 56),
    );
    state = state.copyWith(floatingButtonPosition: clampedPosition);
  }

  // 更新录制覆盖层位置
  void updateRecordingOverlayPosition(Offset delta) {
    final newPosition = state.recordingOverlayPosition + delta;
    state = state.copyWith(recordingOverlayPosition: newPosition);
  }

  @override
  void dispose() {
    _autoClickTimer?.cancel();
    super.dispose();
  }

  // 检查Notifier是否仍然挂载
  bool get mounted {
    // 使用try-catch来检查是否已经被销毁
    // 如果已经被销毁，访问state会抛出异常
    try {
      // 尝试访问state，如果成功则表示未被销毁
      state.isRecording; // 只是访问一下state的属性
      return true;
    } catch (e) {
      return false;
    }
  }
}

// 点击点状态提供者
final clickPointsProvider = StateNotifierProvider<ClickPointsNotifier, ClickPointsState>((ref) {
  final clickPointsController = ref.watch(clickPointsControllerProvider);
  final accessibilityController = ref.watch(accessibilityControllerProvider);
  return ClickPointsNotifier(clickPointsController, accessibilityController, ref);
});