import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserTab {
  String title;
  InAppWebViewController? controller;
  final String tabId;
  final InAppWebViewSettings options;
  final Uri initialUrl;

  BrowserTab({
    required this.title,
    this.controller,
    required this.tabId,
    required this.initialUrl,
    required this.options,
  });
}