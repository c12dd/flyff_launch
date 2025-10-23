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
    return {
      'key': key,
      'displayName': displayName,
      'boundKey': boundKey,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
    };
  }

  // JSON反序列化
  factory ButtonConfig.fromJson(Map<String, dynamic> json) {
    return ButtonConfig(
      key: json['key'],
      displayName: json['displayName'],
      boundKey: json['boundKey'],
      icon: IconData(
        json['iconCodePoint'],
        fontFamily: json['iconFontFamily'],
        fontPackage: json['iconFontPackage'],
      ),
    );
  }
}

// 按钮配置状态
class ButtonConfigState {
  final List<ButtonConfig> buttons;
  final bool isEditMode;

  ButtonConfigState({
    required this.buttons,
    required this.isEditMode,
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
    );
  }

  ButtonConfigState copyWith({
    List<ButtonConfig>? buttons,
    bool? isEditMode,
  }) {
    return ButtonConfigState(
      buttons: buttons ?? this.buttons,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }
}

// 按钮配置Notifier
class ButtonConfigNotifier extends StateNotifier<ButtonConfigState> {
  ButtonConfigNotifier() : super(ButtonConfigState.initial()) {
    _loadButtonConfigs();
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
