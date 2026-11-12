
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/class_model.dart';
import '../models/evaluation_model.dart';
import '../models/question_model.dart';

class IsarService {
  static Isar? _isar;

  // =====================================================
  // DATABASE
  // =====================================================

  // باز کردن دیتابیس
  static Future<Isar> getInstance() async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    final directory = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        ClassModelSchema,
        EvaluationModelSchema,
        QuestionModelSchema,
      ],
      directory: directory.path,
    );

    return _isar!;
  }

  // =====================================================
  // CLASSES
  // =====================================================

  // دریافت تمام صنف‌ها
  static Future<List<ClassModel>> getAllClasses() async {
    final isar = await getInstance();

    return isar.classModels.where().findAll();
  }

  // =====================================================
  // EVALUATIONS
  // =====================================================

  // ذخیره ارزیابی
  static Future<void> saveEvaluation(
    EvaluationModel evaluation,
  ) async {
    final isar = await getInstance();

    if (evaluation.studentName.trim().isEmpty) {
      throw Exception('نام شاگرد الزامی است.');
    }

    await isar.writeTxn(() async {
      await isar.evaluationModels.put(evaluation);
    });

    final saved = await isar.evaluationModels.get(evaluation.id);

    if (saved == null) {
      throw Exception('ذخیره ارزیابی ناموفق بود.');
    }
  }

  // دریافت تمام ارزیابی‌ها
  static Future<List<EvaluationModel>> getAllEvaluations() async {
    final isar = await getInstance();

    return isar.evaluationModels.where().findAll();
  }

  // دریافت ارزیابی‌های یک صنف
  static Future<List<EvaluationModel>> getClassEvaluations(
    int classId,
  ) async {
    final isar = await getInstance();

    final evaluations = await isar.evaluationModels
        .filter()
        .classIdEqualTo(classId)
        .findAll();

    evaluations.sort(
      (a, b) => a.studentName.compareTo(b.studentName),
    );

    return evaluations;
  }

  // دریافت ارزیابی یک شاگرد در یک صنف
  static Future<EvaluationModel?> getStudentEvaluation(
    int classId,
    String studentName,
  ) async {
    final isar = await getInstance();

    final cleanName = studentName.trim();

    if (cleanName.isEmpty) {
      return null;
    }

    final evaluations = await isar.evaluationModels
        .filter()
        .classIdEqualTo(classId)
        .findAll();

    for (final evaluation in evaluations) {
      if (evaluation.studentName.trim() == cleanName) {
        return evaluation;
      }
    }

    return null;
  }

  // بررسی اینکه شاگرد ارزیابی شده یا خیر
  static Future<bool> isStudentEvaluated(
    int classId,
    String studentName,
  ) async {
    final evaluation = await getStudentEvaluation(
      classId,
      studentName,
    );

    return evaluation != null;
  }

  // حذف ارزیابی یک شاگرد
  static Future<void> deleteStudentEvaluation(
    int classId,
    String studentName,
  ) async {
    final isar = await getInstance();

    final evaluation = await getStudentEvaluation(
      classId,
      studentName,
    );

    if (evaluation == null) {
      return;
    }

    await isar.writeTxn(() async {
      await isar.evaluationModels.delete(evaluation.id);
    });
  }

  // حذف ارزیابی‌های یک صنف
  static Future<void> deleteClassEvaluations(
    int classId,
  ) async {
    final isar = await getInstance();

    final evaluations = await isar.evaluationModels
        .filter()
        .classIdEqualTo(classId)
        .findAll();

    if (evaluations.isEmpty) {
      return;
    }

    final ids = evaluations
        .map((evaluation) => evaluation.id)
        .toList();

    await isar.writeTxn(() async {
      await isar.evaluationModels.deleteAll(ids);
    });
  }

  // =====================================================
  // QUESTION BANK
  // =====================================================

  // ذخیره سوالات جدید
  // سوالات قبلی بانک با سوالات جدید جایگزین می‌شوند.
  // ارزیابی‌های قبلی حذف نمی‌شوند.
  static Future<void> saveQuestions(
    List<QuestionModel> questions,
  ) async {
    if (questions.isEmpty) {
      throw Exception('هیچ سوالی برای ذخیره وجود ندارد.');
    }

    final isar = await getInstance();

    await isar.writeTxn(() async {
      await isar.questionModels.clear();

      await isar.questionModels.putAll(questions);
    });

    final savedQuestions = await getAllQuestions();

    if (savedQuestions.length != questions.length) {
      throw Exception('ذخیره تمام سوالات موفق نبود.');
    }
  }

  // دریافت تمام سوالات
  static Future<List<QuestionModel>> getAllQuestions() async {
    final isar = await getInstance();

    return isar.questionModels.where().findAll();
  }

  // تعداد سوالات
  static Future<int> getQuestionCount() async {
    final isar = await getInstance();

    return isar.questionModels.count();
  }

  // حذف تمام سوالات بانک
  // این متد ارزیابی‌های قبلی را حذف نمی‌کند.
  static Future<void> deleteAllQuestions() async {
    final isar = await getInstance();

    await isar.writeTxn(() async {
      await isar.questionModels.clear();
    });
  }
}
