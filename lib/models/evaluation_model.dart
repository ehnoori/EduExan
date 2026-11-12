
import 'package:isar/isar.dart';

part 'evaluation_model.g.dart';

@collection
class EvaluationModel {
  Id id = Isar.autoIncrement;

  // مشخصات صنف
  late int classId;
  late String className;

  // مشخصات شاگرد
  late String studentName;

  // پاسخ‌های شاگرد
  late List<String> answers;

  // تعداد سوالات
  late int totalQuestions;

  // تعداد پاسخ‌های درست
  int correctAnswers = 0;

  // تاریخ ارزیابی
  late DateTime evaluatedAt;

  /// نسخه ثابت سوالات صنف در زمان ارزیابی
  /// سوالات به شکل JSON ذخیره می‌شوند.
  /// این فیلد برای حفظ سوالات ارزیابی‌های قبلی است.
  String questionSnapshotJson = '';
}
