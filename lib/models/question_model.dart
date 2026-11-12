
import 'package:isar/isar.dart';

part 'question_model.g.dart';

@collection
class QuestionModel {
  Id id = Isar.autoIncrement;

  /// متن سوال
  late String question;

  /// نوع سوال: choice, number, text, project
  late String type;

  /// گزینه‌های سوال
  late List<String> options;

  /// پاسخ درست؛ برای سوالات بدون پاسخ درست خالی می‌ماند.
  String? correctAnswer;
}
