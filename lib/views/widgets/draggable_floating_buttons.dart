import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flyff_launch/providers/button_config_provider.dart';

// 按钮位置状态Provider
final buttonPositionsProvider = StateProvider<Map<String, Offset>>((ref) => {});

class DraggableFloatingButtons extends HookConsumerWidget {
  final Function(String)? onButtonPressed;

  const DraggableFloatingButtons({
    super.key,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonPositions = ref.watch(buttonPositionsProvider);
    final buttonConfigState = ref.watch(buttonConfigProvider);
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    
    // 初始化按钮位置
    useEffect(() {
      _loadButtonPositions(ref);
      return null;
    }, []);

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
        final buttonPosition = buttonPositions[button.key] ?? 
            Offset(defaultX, defaultY);

        return DraggableButton(
          key: ValueKey(button.key),
          icon: button.icon,
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
    
    final currentPositions = ref.read(buttonPositionsProvider);
    final updatedPositions = Map<String, Offset>.from(currentPositions);
    updatedPositions[buttonKey] = clampedPosition;
    ref.read(buttonPositionsProvider.notifier).state = updatedPositions;
    
    // 自动保存位置
    _saveButtonPositions(ref);
  }

  // 保存按钮位置到SharedPreferences
  Future<void> _saveButtonPositions(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final positions = ref.read(buttonPositionsProvider);
    
    for (final entry in positions.entries) {
      await prefs.setDouble('${entry.key}_x', entry.value.dx);
      await prefs.setDouble('${entry.key}_y', entry.value.dy);
    }
  }

  // 从SharedPreferences加载按钮位置
  Future<void> _loadButtonPositions(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final positions = <String, Offset>{};
    final buttonConfigState = ref.read(buttonConfigProvider);
    
    // 加载所有按钮的位置
    for (final button in buttonConfigState.buttons) {
      final buttonX = prefs.getDouble('${button.key}_x');
      final buttonY = prefs.getDouble('${button.key}_y');
      if (buttonX != null && buttonY != null) {
        positions[button.key] = Offset(buttonX, buttonY);
      }
    }
    
    if (positions.isNotEmpty) {
      ref.read(buttonPositionsProvider.notifier).state = positions;
    }
  }
}

class DraggableButton extends HookWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Offset initialPosition;
  final Function(Offset)? onPositionChanged;

  const DraggableButton({
    super.key,
    required this.icon,
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
            // 通知位置变化
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
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}