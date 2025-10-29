import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

HeadlessInAppWebView? _headlessPrewarmWebView;

Future<void> enableServiceWorkersIfAvailable() async {
  if (!Platform.isAndroid) return;

  try {
    final basicSupported = await AndroidWebViewFeature.isFeatureSupported(
      AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE,
    );
    final interceptSupported = await AndroidWebViewFeature.isFeatureSupported(
      AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST,
    );

    if (basicSupported) {
      final controller = ServiceWorkerController.instance();
      if (interceptSupported) {
        await controller.setServiceWorkerClient(
          ServiceWorkerClient(shouldInterceptRequest: (request) async {
            return null; // 不拦截，仅启用 SW 支持
          }),
        );
      }
    }
  } catch (e, st) {
    debugPrint('Failed to enable service workers: $e\n$st');
  }
}

Future<void> prewarmWebViewCache(Uri url, {Duration holdDuration = const Duration(seconds: 2)}) async {
  // 已经在预热了
  if (_headlessPrewarmWebView != null) return;

  try {
    _headlessPrewarmWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri.uri(url)),
      onLoadStop: (controller, _) async {
        // 给 Service Worker/缓存一点时间完成安装与写入
        await Future.delayed(holdDuration);
        await _headlessPrewarmWebView?.dispose();
        _headlessPrewarmWebView = null;
      },
      onReceivedError: (controller, request, error) async {
        await _headlessPrewarmWebView?.dispose();
        _headlessPrewarmWebView = null;
      },
    );

    await _headlessPrewarmWebView!.run();
  } catch (e, st) {
    debugPrint('Prewarm webview failed: $e\n$st');
    try {
      await _headlessPrewarmWebView?.dispose();
    } catch (_) {}
    _headlessPrewarmWebView = null;
  }
}


