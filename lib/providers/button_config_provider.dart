import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 按钮配置模型
class ButtonConfig {
  final String key;
  final String displayName;
  final String boundKey;
  final IconData icon;

  ButtonConfig({
    required this.key,
    required this.displayName,
    required this.boundKey,
    required this.icon,
  });

  ButtonConfig copyWith({
    String? key,
    String? displayName,
    String? boundKey,
    IconData? icon,
  }) {
    return ButtonConfig(
      key: key ?? this.key,
      displayName: displayName ?? this.displayName,
      boundKey: boundKey ?? this.boundKey,
      icon: icon ?? this.icon,
    );
  }

  // JSON序列化
  Map<String, dynamic> toJson() {
    // 将IconData转换为字符串名称
    String iconName = 'add';
    if (icon == Icons.add) {
      iconName = 'add';
    } else if (icon == Icons.remove) {
      iconName = 'remove';
    } else if (icon == Icons.edit) {
      iconName = 'edit';
    } else if (icon == Icons.save) {
      iconName = 'save';
    } else if (icon == Icons.delete) {
      iconName = 'delete';
    } else if (icon == Icons.settings) {
      iconName = 'settings';
    } else if (icon == Icons.home) {
      iconName = 'home';
    } else if (icon == Icons.search) {
      iconName = 'search';
    } else if (icon == Icons.favorite) {
      iconName = 'favorite';
    } else if (icon == Icons.star) {
      iconName = 'star';
    }
    
    return {
      'key': key,
      'displayName': displayName,
      'boundKey': boundKey,
      'iconName': iconName,
    };
  }

  // JSON反序列化
  factory ButtonConfig.fromJson(Map<String, dynamic> json) {
    // 使用预定义的IconData常量避免tree-shaking问题
    final iconName = json['iconName'] as String? ?? 'add';
    IconData iconData;
    
    switch (iconName) {
      case 'add':
        iconData = Icons.add;
        break;
      case 'remove':
        iconData = Icons.remove;
        break;
      case 'edit':
        iconData = Icons.edit;
        break;
      case 'save':
        iconData = Icons.save;
        break;
      case 'delete':
        iconData = Icons.delete;
        break;
      case 'settings':
        iconData = Icons.settings;
        break;
      case 'home':
        iconData = Icons.home;
        break;
      case 'search':
        iconData = Icons.search;
        break;
      case 'favorite':
        iconData = Icons.favorite;
        break;
      case 'star':
        iconData = Icons.star;
        break;
      default:
        iconData = Icons.add;
    }
    
    return ButtonConfig(
      key: json['key'],
      displayName: json['displayName'],
      boundKey: json['boundKey'],
      icon: iconData,
    );
  }
}

// 按钮配置状态
class ButtonConfigState {
  final List<ButtonConfig> buttons;
  final bool isEditMode;
  final int controllerCount; // 控制器数量，0表示所有
  final Map<String, Offset> buttonPositions; // 按钮位置

  ButtonConfigState({
    required this.buttons,
    required this.isEditMode,
    required this.controllerCount,
    this.buttonPositions = const {},
  });

  factory ButtonConfigState.initial() {
    return ButtonConfigState(
      buttons: [
        ButtonConfig(
          key: 'button1',
          displayName: '按钮1',
          boundKey: '1',
          icon: Icons.looks_one,
        ),
        ButtonConfig(
          key: 'button2',
          displayName: '按钮2',
          boundKey: '2',
          icon: Icons.looks_two,
        ),
      ],
      isEditMode: false,
      controllerCount: 0, // 默认所有控制器
    );
  }

  ButtonConfigState copyWith({
    List<ButtonConfig>? buttons,
    bool? isEditMode,
    int? controllerCount,
    Map<String, Offset>? buttonPositions,
  }) {
    return ButtonConfigState(
      buttons: buttons ?? this.buttons,
      isEditMode: isEditMode ?? this.isEditMode,
      controllerCount: controllerCount ?? this.controllerCount,
      buttonPositions: buttonPositions ?? this.buttonPositions,
    );
  }
}

// 按钮配置Notifier
class ButtonConfigNotifier extends StateNotifier<ButtonConfigState> {
  ButtonConfigNotifier() : super(ButtonConfigState.initial()) {
    _initialize();
  }
  
  // 异步初始化
  Future<void> _initialize() async {
    debugPrint('🔧 ButtonConfigNotifier: Starting initialization...');
    await _loadButtonConfigs();
    await _loadControllerCount();
    await _loadButtonPositions();
    debugPrint('🔧 ButtonConfigNotifier: Initialization complete. Buttons: ${state.buttons.length}');
  }
  
  // 加载按钮位置
  Future<void> _loadButtonPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positions = <String, Offset>{};
      
      for (final button in state.buttons) {
        final buttonX = prefs.getDouble('${button.key}_x');
        final buttonY = prefs.getDouble('${button.key}_y');
        if (buttonX != null && buttonY != null) {
          positions[button.key] = Offset(buttonX, buttonY);
        }
      }
      
      if (positions.isNotEmpty) {
        state = state.copyWith(buttonPositions: positions);
      }
    } catch (e) {
      print('Error loading button positions: $e');
    }
  }
  
  // 保存按钮位置
  Future<void> saveButtonPosition(String buttonKey, Offset position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${buttonKey}_x', position.dx);
      await prefs.setDouble('${buttonKey}_y', position.dy);
      
      // 更新状态
      final updatedPositions = Map<String, Offset>.from(state.buttonPositions);
      updatedPositions[buttonKey] = position;
      state = state.copyWith(buttonPositions: updatedPositions);
    } catch (e) {
      print('Error saving button position: $e');
    }
  }

  // 加载按钮配置
  Future<void> _loadButtonConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = prefs.getString('button_configs');
      
      if (configsJson != null) {
        final List<dynamic> configsList = json.decode(configsJson);
        final List<ButtonConfig> configs = configsList
            .map((json) => ButtonConfig.fromJson(json))
            .toList();
        
        state = state.copyWith(buttons: configs);
      }
    } catch (e) {
      print('加载按钮配置失败: $e');
      // 如果加载失败，使用默认配置
    }
  }

  // 保存按钮配置
  Future<void> _saveButtonConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = json.encode(
        state.buttons.map((config) => config.toJson()).toList(),
      );
      await prefs.setString('button_configs', configsJson);
    } catch (e) {
      print('保存按钮配置失败: $e');
    }
  }

  // 切换编辑模式
  void toggleEditMode() {
    state = state.copyWith(isEditMode: !state.isEditMode);
  }

  // 添加新按钮
  void addButton() {
    final newButtonCount = state.buttons.length + 1;
    final newButton = ButtonConfig(
      key: 'button$newButtonCount',
      displayName: '按钮$newButtonCount',
      boundKey: '$newButtonCount',
      icon: _getIconForButton(newButtonCount),
    );
    
    final updatedButtons = [...state.buttons, newButton];
    state = state.copyWith(buttons: updatedButtons);
    _saveButtonConfigs(); // 自动保存
  }

  // 删除按钮
  void removeButton(String buttonKey) {
    if (state.buttons.length <= 1) return; // 至少保留一个按钮
    
    final updatedButtons = state.buttons.where((button) => button.key != buttonKey).toList();
    state = state.copyWith(buttons: updatedButtons);
    _saveButtonConfigs(); // 自动保存
  }

  // 更新按钮配置
  void updateButtonConfig(String buttonKey, String newBoundKey) {
    final updatedButtons = state.buttons.map((button) {
      if (button.key == buttonKey) {
        return button.copyWith(boundKey: newBoundKey);
      }
      return button;
    }).toList();

    state = state.copyWith(buttons: updatedButtons);
    _saveButtonConfigs(); // 自动保存
  }

  // 更新按钮显示名称
  void updateButtonDisplayName(String buttonKey, String newDisplayName) {
    final updatedButtons = state.buttons.map((button) {
      if (button.key == buttonKey) {
        return button.copyWith(displayName: newDisplayName);
      }
      return button;
    }).toList();

    state = state.copyWith(buttons: updatedButtons);
    _saveButtonConfigs(); // 自动保存
  }

  // 更新控制器数量
  void updateControllerCount(int count) {
    state = state.copyWith(controllerCount: count);
    _saveControllerCount(count);
  }

  // 保存控制器数量
  Future<void> _saveControllerCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('controller_count', count);
    } catch (e) {
      print('保存控制器数量失败: $e');
    }
  }

  // 加载控制器数量
  Future<void> _loadControllerCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt('controller_count') ?? 0;
      state = state.copyWith(controllerCount: count);
    } catch (e) {
      print('加载控制器数量失败: $e');
    }
  }

  // 获取按钮配置
  ButtonConfig? getButtonConfig(String buttonKey) {
    try {
      return state.buttons.firstWhere((button) => button.key == buttonKey);
    } catch (e) {
      return null;
    }
  }

  // 根据按钮编号获取图标
  IconData _getIconForButton(int buttonNumber) {
    switch (buttonNumber) {
      case 1: return Icons.looks_one;
      case 2: return Icons.looks_two;
      case 3: return Icons.looks_3;
      case 4: return Icons.looks_4;
      case 5: return Icons.looks_5;
      case 6: return Icons.looks_6;
      default: return Icons.circle;
    }
  }
}

// 按钮配置Provider
final buttonConfigProvider = StateNotifierProvider<ButtonConfigNotifier, ButtonConfigState>((ref) {
  return ButtonConfigNotifier();
});
