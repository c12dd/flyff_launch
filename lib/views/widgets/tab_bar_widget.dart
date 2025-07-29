import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flyff_launch/providers/browser_provider.dart';
import 'package:flyff_launch/controllers/browser_controller.dart';

class TabBarWidget extends HookConsumerWidget {
  const TabBarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserState = ref.watch(browserTabsProvider);
    final browserNotifier = ref.read(browserTabsProvider.notifier);
    final browserController = ref.read(browserControllerProvider);

    return Container(
      height: 48,
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: browserState.tabs.length + 1,
              itemBuilder: (context, index) {
                if (index == browserState.tabs.length) {
                  return IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => browserNotifier.addNewTab(),
                  );
                }
                final isSelected = index == browserState.currentIndex;
                return _buildTabItem(
                  context,
                  index,
                  isSelected,
                  browserState,
                  browserNotifier,
                  browserController,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    int index,
    bool isSelected,
    BrowserTabsState browserState,
    BrowserTabsNotifier browserNotifier,
    BrowserController browserController,
  ) {
    return GestureDetector(
      onTap: () => browserNotifier.switchTab(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.deepPurple, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              browserState.tabs[index].title,
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (browserState.tabs.length > 1)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final shouldClose = await browserController.showCloseTabDialog(context);
                  if (shouldClose == true) {
                    browserNotifier.closeTab(index);
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final shouldReload = await browserController.showReloadTabDialog(context);
                if (shouldReload == true) {
                  browserState.tabs[index].controller?.reload();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}