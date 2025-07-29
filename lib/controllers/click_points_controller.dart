import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flyff_launch/models/click_point.dart';

class ClickPointsController {
  // 保存点击点到本地存储
  Future<void> saveClickPoints(List<Offset> clickPoints) async {
    final prefs = await SharedPreferences.getInstance();
    final points = clickPoints.map((e) => {'dx': e.dx, 'dy': e.dy}).toList();
    await prefs.setString('click_points', json.encode(points));
  }

  // 从本地存储加载点击点
  Future<List<Offset>> loadClickPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('click_points');
    if (str != null && str.isNotEmpty) {
      try {
        final List list = json.decode(str);
        return list
            .map((e) => Offset(
                  (e['dx'] as num).toDouble(),
                  (e['dy'] as num).toDouble(),
                ))
            .toList();
      } catch (e) {
        // 处理错误
        return [];
      }
    }
    return [];
  }

  // 清除所有点击点
  Future<void> clearClickPoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('click_points');
  }
}