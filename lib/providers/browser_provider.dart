import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flyff_launch/models/browser_tab.dart';
import 'package:flyff_launch/controllers/browser_controller.dart';

// 浏览器控制器提供者
final browserControllerProvider = Provider<BrowserController>((ref) {
  return BrowserController();
});

// 浏览器标签页状态
class BrowserTabsState {
  final List<BrowserTab> tabs;
  final int currentIndex;
  final int tabCount;

  BrowserTabsState({
    required this.tabs,
    required this.currentIndex,
    required this.tabCount,
  });

  // 创建初始状态
  factory BrowserTabsState.initial() {
    return BrowserTabsState(
      tabs: [],
      currentIndex: 0,
      tabCount: 1,
    );
  }

  // 创建状态的副本
  BrowserTabsState copyWith({
    List<BrowserTab>? tabs,
    int? currentIndex,
    int? tabCount,
  }) {
    return BrowserTabsState(
      tabs: tabs ?? this.tabs,
      currentIndex: currentIndex ?? this.currentIndex,
      tabCount: tabCount ?? this.tabCount,
    );
  }
}

// 浏览器标签页状态Notifier
class BrowserTabsNotifier extends StateNotifier<BrowserTabsState> {
  final BrowserController _controller;

  BrowserTabsNotifier(this._controller) : super(BrowserTabsState.initial()) {
    // 初始化时添加一个新标签页
    addNewTab();
  }

  // 添加新标签页
  void addNewTab() {
    final newTab = _controller.createNewTab(state.tabCount);
    final newTabs = [...state.tabs, newTab];
    state = state.copyWith(
      tabs: newTabs,
      currentIndex: newTabs.length - 1,
      tabCount: state.tabCount + 1,
    );
  }

  // 关闭标签页
  void closeTab(int index) {
    if (state.tabs.length <= 1) return;

    // 创建新的标签页列表，移除指定索引的标签页
    final newTabs = [...state.tabs];
    newTabs.removeAt(index);

    // 计算新的当前索引
    int newIndex = state.currentIndex;
    if (index == state.currentIndex) {
      // 如果关闭的是当前标签页，选择下一个或前一个标签页
      newIndex = index >= newTabs.length ? newTabs.length - 1 : index;
    } else if (index < state.currentIndex) {
      // 如果关闭的标签页在当前标签页之前，当前索引需要减1
      newIndex = state.currentIndex - 1;
    }

    // 更新状态，保持其他标签页的控制器不变
    state = state.copyWith(
      tabs: newTabs,
      currentIndex: newIndex,
    );
    
    // 可以在这里添加关闭标签页的清理逻辑，如有必要
  }

  // // 切换标签页
  // void switchTab(int index) {
  //   if (index >= 0 && index < state.tabs.length && index != state.currentIndex) {
  //     // 只在索引不同时更新状态，避免不必要的重建
  //     state = state.copyWith(currentIndex: index);
  //   }
  // }

  // 更新标签页标题
  void updateTabTitle(int index, String title) {
    if (index >= 0 && index < state.tabs.length) {
      final newTabs = [...state.tabs];
      newTabs[index] = BrowserTab(
        title: title,
        controller: newTabs[index].controller,
        tabId: newTabs[index].tabId,
        initialUrl: newTabs[index].initialUrl,
        options: newTabs[index].options,
      );
      state = state.copyWith(tabs: newTabs);
    }
  }

  // 更新标签页控制器
  void updateTabController(int index, controller) {
    if (index >= 0 && index < state.tabs.length) {
      final newTabs = [...state.tabs];
      newTabs[index].controller = controller;
      state = state.copyWith(tabs: newTabs);
    }
  }

  // 刷新当前标签页
  void reloadCurrentTab() {
    if (state.currentIndex >= 0 && state.currentIndex < state.tabs.length) {
      state.tabs[state.currentIndex].controller?.reload();
    }
  }
}

// 浏览器标签页状态提供者
final browserTabsProvider = StateNotifierProvider<BrowserTabsNotifier, BrowserTabsState>((ref) {
  final controller = ref.watch(browserControllerProvider);
  return BrowserTabsNotifier(controller);
});