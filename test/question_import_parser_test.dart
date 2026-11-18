import 'package:flutter_test/flutter_test.dart';

import 'package:eduexam/services/question_import_parser.dart';

void main() {
  group('parseQuestionRows', () {
    test('parses all question types and their options', () {
      final questions = parseQuestionRows([
        [
          'Question',
          'Type',
          'Option A',
          'Option B',
          'Option C',
          'Option D',
          'CorrectAnswer',
        ],
        [
          'پایتخت افغانستان کدام شهر است؟',
          'choice',
          'کابل',
          'هرات',
          '',
          '',
          'A',
        ],
        ['حاصل جمع ۱۲ و ۸ چند است؟', 'number', '', '', '', '', '20'],
        ['چرا آموزش مهم است؟', 'text', '', '', '', '', 'افزایش دانش'],
        ['پروژه آماده است؟', 'project', '', '', '', '', 'بلی'],
      ]);

      expect(questions, hasLength(4));
      expect(questions.map((question) => question.type), [
        'choice',
        'number',
        'text',
        'project',
      ]);
      expect(questions.first.options, ['کابل', 'هرات']);
      expect(questions.first.correctAnswer, 'A');
      expect(questions.last.correctAnswer, 'بلی');
    });

    test('keeps legacy files without a Type column as text questions', () {
      final questions = parseQuestionRows([
        ['Question', 'CorrectAnswer'],
        ['پرسش قدیمی', 'پاسخ نمونه'],
      ]);

      expect(questions.single.type, 'text');
      expect(questions.single.correctAnswer, 'پاسخ نمونه');
    });

    test('rejects choice questions with fewer than two options', () {
      expect(
        () => parseQuestionRows([
          ['Question', 'Type', 'Option A', 'Option B', 'CorrectAnswer'],
          ['یک پرسش', 'choice', 'گزینهٔ نخست', '', 'A'],
        ]),
        throwsA(isA<Exception>()),
      );
    });
  });
}
