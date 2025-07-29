import 'dart:ui';

class ClickPoint {
  final Offset position;

  ClickPoint({required this.position});

  // 从JSON转换为ClickPoint对象
  factory ClickPoint.fromJson(Map<String, dynamic> json) {
    return ClickPoint(
      position: Offset(
        (json['dx'] as num).toDouble(),
        (json['dy'] as num).toDouble(),
      ),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'dx': position.dx,
      'dy': position.dy,
    };
  }
}