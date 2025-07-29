import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flyff_launch/providers/click_provider.dart';

class FloatingActionButtonWidget extends HookConsumerWidget {
  const FloatingActionButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clickState = ref.watch(clickPointsProvider);
    final clickNotifier = ref.read(clickPointsProvider.notifier);
    final accessibilityEnabled = ref.watch(accessibilityEnabledProvider);

    return Positioned(
      left: clickState.floatingButtonPosition.dx,
      top: clickState.floatingButtonPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final screenSize = MediaQuery.of(context).size;
          clickNotifier.updateFloatingButtonPosition(details.delta, screenSize);
        },
        child: GestureDetector(
          onLongPress: () {
            clickNotifier.toggleRecording();
          },
          child: FloatingActionButton(
            backgroundColor: clickState.isRecording
                ? Colors.red
                : clickState.isAutoClicking
                    ? Colors.green
                    : Colors.blue,
            onPressed: () {
              if (clickState.isRecording) {
                // 如果正在录制，点击不执行任何操作
                return;
              }
              clickNotifier.startAutoClicking(context);
            },
            child: Icon(
              clickState.isRecording
                  ? Icons.fiber_manual_record
                  : clickState.isAutoClicking
                      ? Icons.stop
                      : accessibilityEnabled
                          ? Icons.touch_app
                          : Icons.warning,
            ),
        ),
      ),
    ),
  );
  }
}