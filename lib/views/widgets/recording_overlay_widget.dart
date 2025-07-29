import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flyff_launch/providers/click_provider.dart';

class RecordingOverlayWidget extends HookConsumerWidget {
  const RecordingOverlayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clickState = ref.watch(clickPointsProvider);
    final clickNotifier = ref.read(clickPointsProvider.notifier);

    if (!clickState.isRecording) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Stack(
        children: [
          // 透明覆盖层，用于捕获点击
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                clickNotifier.addClickPoint(details.localPosition);
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          
          // 显示已记录的点击点
          ...clickState.points.map((point) => Positioned(
                left: point.dx - 10,
                top: point.dy - 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              )),
          
          // 控制手柄
          Positioned(
            left: clickState.recordingOverlayPosition.dx,
            top: clickState.recordingOverlayPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                clickNotifier.updateRecordingOverlayPosition(details.delta);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.drag_indicator,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}