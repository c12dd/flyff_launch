import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flyff_launch/providers/button_config_provider.dart';

class DraggableFloatingButtons extends HookConsumerWidget {
  final Function(String)? onButtonPressed;

  const DraggableFloatingButtons({
    super.key,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonConfigState = ref.watch(buttonConfigProvider);
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // 计算可用的拖拽区域
    const appBarHeight = 48.0; // AppBar高度
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom - appBarHeight;
    final availableWidth = screenSize.width - safeArea.left - safeArea.right;
    
    return Stack(
      children: buttonConfigState.buttons.asMap().entries.map((entry) {
        final index = entry.key;
        final button = entry.value;
        
        // 获取按钮位置，如果没有保存的位置则使用默认位置
        final defaultX = availableWidth - (60 + index * 60);
        final defaultY = availableHeight - 100;
        final buttonPosition = buttonConfigState.buttonPositions[button.key] ?? 
            Offset(defaultX, defaultY);

        return DraggableButton(
          key: ValueKey(button.key),
          displayText: button.boundKey,
          initialPosition: buttonPosition,
          onPressed: () => onButtonPressed?.call(button.boundKey),
          onPositionChanged: (position) => _updateButtonPosition(
            ref, 
            button.key, 
            position,
            screenSize,
            safeArea,
            appBarHeight,
          ),
        );
      }).toList(),
    );
  }

  // 更新按钮位置并自动保存
  void _updateButtonPosition(
    WidgetRef ref, 
    String buttonKey, 
    Offset position,
    Size screenSize,
    EdgeInsets safeArea,
    double appBarHeight,
  ) {
    // position 已经是相对于Stack的坐标，直接使用
    // 只需要确保不超出可用区域
    final availableWidth = screenSize.width - safeArea.left - safeArea.right;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom - appBarHeight;
    
    const buttonSize = 56.0;
    final clampedX = position.dx.clamp(0.0, availableWidth - buttonSize);
    final clampedY = position.dy.clamp(0.0, availableHeight - buttonSize);
    
    final clampedPosition = Offset(clampedX, clampedY);
    
    // 使用ButtonConfigNotifier保存位置
    final buttonConfigNotifier = ref.read(buttonConfigProvider.notifier);
    buttonConfigNotifier.saveButtonPosition(buttonKey, clampedPosition);
  }


}

class DraggableButton extends HookWidget {
  final String displayText;
  final VoidCallback? onPressed;
  final Offset initialPosition;
  final Function(Offset)? onPositionChanged;

  const DraggableButton({
    super.key,
    required this.displayText,
    required this.initialPosition,
    this.onPressed,
    this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final position = useState(initialPosition);
    final isDragging = useState(false);
    final dragStartPosition = useState<Offset?>(null);

    return Positioned(
      left: position.value.dx,
      top: position.value.dy,
      child: GestureDetector(
        onPanStart: (details) {
          isDragging.value = true;
          dragStartPosition.value = details.localPosition;
        },
        onPanUpdate: (details) {
          if (isDragging.value && dragStartPosition.value != null) {
            // 计算新的位置
            final newPosition = position.value + details.delta;
            position.value = newPosition;
          }
        },
        onPanEnd: (details) {
          if (isDragging.value) {
            // 通知位置变化并立即保存
            onPositionChanged?.call(position.value);
          }
          isDragging.value = false;
          dragStartPosition.value = null;
        },
        onTap: () {
          if (!isDragging.value) {
            onPressed?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDragging.value ? Colors.deepPurple.withOpacity(0.8) : Colors.deepPurple,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isDragging.value ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              displayText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}