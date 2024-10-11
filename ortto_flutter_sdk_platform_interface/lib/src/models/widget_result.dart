
class WidgetResult {
  bool? success;
  String? message;

  WidgetResult({
    this.success,
    this.message,
  });

  WidgetResult.fromMap(Map<String, dynamic> map) {
    success = map['success'] as bool?;
    message = map['message'] as String?;
  }
}