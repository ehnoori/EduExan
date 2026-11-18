import '../models/question_model.dart';

List<QuestionModel> parseQuestionRows(List<List<String>> rows) {
  if (rows.length < 2) {
    throw Exception('فایل باید عنوان ستون‌ها و حداقل یک سوال داشته باشد.');
  }

  String normalizeHeader(String value) {
    return value
        .replaceAll('\uFEFF', '')
        .replaceAll('\u200C', ' ')
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  final headers = rows.first.map(normalizeHeader).toList();

  int findColumn(List<String> aliases) {
    return headers.indexWhere(aliases.contains);
  }

  final questionIndex = findColumn(['question', 'سوال', 'سؤال']);
  final typeIndex = findColumn(['type', 'نوع', 'نوع سوال', 'نوع سؤال']);
  final correctIndex = findColumn([
    'correct answer',
    'correctanswer',
    'پاسخ درست',
    'پاسخ صحیح',
  ]);
  final optionIndices = [
    findColumn(['option a', 'optiona', 'گزینه a', 'گزینه الف']),
    findColumn(['option b', 'optionb', 'گزینه b', 'گزینه ب']),
    findColumn(['option c', 'optionc', 'گزینه c', 'گزینه ج']),
    findColumn(['option d', 'optiond', 'گزینه d', 'گزینه د']),
  ];

  if (questionIndex == -1) {
    throw Exception('ستون Question یا سوال پیدا نشد.');
  }

  if (correctIndex == -1) {
    throw Exception('ستون CorrectAnswer یا پاسخ درست پیدا نشد.');
  }

  String getCell(List<String> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index].trim();
  }

  final importedQuestions = <QuestionModel>[];

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    final questionText = getCell(row, questionIndex);
    final correctAnswer = getCell(row, correctIndex);

    if (questionText.isEmpty && correctAnswer.isEmpty) continue;

    if (questionText.isEmpty) {
      throw Exception('متن سوال در ردیف ${i + 1} خالی است.');
    }

    if (correctAnswer.isEmpty) {
      throw Exception('پاسخ سوال در ردیف ${i + 1} خالی است.');
    }

    final type = typeIndex == -1 || getCell(row, typeIndex).isEmpty
        ? 'text'
        : getCell(row, typeIndex).toLowerCase();

    if (!const ['choice', 'number', 'text', 'project'].contains(type)) {
      throw Exception('نوع سوال در ردیف ${i + 1} معتبر نیست: $type');
    }

    final options = type == 'choice'
        ? optionIndices
              .map((index) => getCell(row, index))
              .where((option) => option.isNotEmpty)
              .toList()
        : <String>[];

    if (type == 'choice' && options.length < 2) {
      throw Exception(
        'سوال چندگزینه‌ای در ردیف ${i + 1} باید حداقل دو گزینه داشته باشد.',
      );
    }

    importedQuestions.add(
      QuestionModel()
        ..question = questionText
        ..type = type
        ..options = options
        ..correctAnswer = correctAnswer,
    );
  }

  if (importedQuestions.isEmpty) {
    throw Exception('هیچ سوال معتبری پیدا نشد.');
  }

  return importedQuestions;
}
