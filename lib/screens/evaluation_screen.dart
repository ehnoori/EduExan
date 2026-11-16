
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/isar_service.dart';
import '../models/class_model.dart';
import '../models/evaluation_model.dart';
import '../models/question_model.dart';

class EvaluationScreen extends StatefulWidget {
  final ClassModel classModel;
  final String studentName;

  const EvaluationScreen({
    super.key,
    required this.classModel,
    required this.studentName,
  });

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  static const Color backgroundColor = Color(0xFFF0F6FF);
  static const Color primaryColor = Color(0xFF6C5CE7);

  int currentQuestion = 0;

  List<String?> answers = [];

  /// نسخه سوالاتی که شاگرد در همین ارزیابی دریافت می‌کند.
  List<Map<String, dynamic>> examQuestions = [];

  final TextEditingController textController = TextEditingController();
  final TextEditingController projectController = TextEditingController();

  bool isSaving = false;
  bool isLoading = true;
  bool alreadyEvaluated = false;

  @override
  void initState() {
    super.initState();
    loadExamQuestions();
  }

  @override
  void dispose() {
    textController.dispose();
    projectController.dispose();
    super.dispose();
  }

  // =====================================================
  // QUESTION SNAPSHOT
  // =====================================================

  Map<String, dynamic> questionToMap(QuestionModel question) {
    return {
      'question': question.question,
      'type': question.type,
      'options': question.options,
      'correctAnswer': question.correctAnswer,
    };
  }

  List<Map<String, dynamic>> decodeSnapshot(String json) {
    final decoded = jsonDecode(json);

    if (decoded is! List) {
      throw Exception('نسخه ذخیره‌شده سوالات معتبر نیست.');
    }

    return decoded.map((item) {
      final map = Map<String, dynamic>.from(item as Map);

      return {
        'question': map['question']?.toString() ?? '',
        'type': map['type']?.toString() ?? '',
        'options': (map['options'] as List? ?? [])
            .map((option) => option.toString())
            .toList(),
        'correctAnswer': map['correctAnswer']?.toString(),
      };
    }).toList();
  }

  String encodeSnapshot(List<Map<String, dynamic>> questions) {
    return jsonEncode(questions);
  }

  // =====================================================
  // LOAD QUESTIONS
  // =====================================================

  Future<void> loadExamQuestions() async {
    try {
      final cleanStudentName = widget.studentName.trim();

      if (cleanStudentName.isEmpty) {
        throw Exception('نام شاگرد معتبر نیست.');
      }

      // بررسی می‌کنیم شاگرد قبلاً ارزیابی شده است یا خیر.
      final existingStudent = await IsarService.getStudentEvaluation(
        widget.classModel.id,
        cleanStudentName,
      );

      if (existingStudent != null) {
        if (!mounted) return;

        setState(() {
          alreadyEvaluated = true;
          isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _showMessage(
            'این شاگرد قبلاً در این صنف ارزیابی شده است. نتیجه قبلی تغییر نمی‌کند.',
          );

          Navigator.pop(context, false);
        });

        return;
      }

      // هر شاگرد ارزیابی‌نشده، سوالات بانک فعال فعلی را دریافت می‌کند.
      final databaseQuestions = await IsarService.getAllQuestions();

      if (databaseQuestions.isEmpty) {
        throw Exception(
          'هیچ سوالی در برنامه وجود ندارد. ابتدا فایل Excel سوالات را وارد کنید.',
        );
      }

      final loadedQuestions = databaseQuestions
          .map(questionToMap)
          .toList();

      if (loadedQuestions.isEmpty) {
        throw Exception('سوال معتبری برای این صنف پیدا نشد.');
      }

      // بررسی اعتبار سوالات.
      for (final question in loadedQuestions) {
        final type = question['type']?.toString() ?? '';
        final questionText = question['question']?.toString() ?? '';

        if (questionText.trim().isEmpty ||
            !['choice', 'number', 'text', 'project'].contains(type)) {
          throw Exception('ساختار یکی از سوالات معتبر نیست.');
        }

        if (type == 'choice') {
          final options = question['options'] as List;

          if (options.length < 2) {
            throw Exception(
              'یک سوال چندگزینه‌ای کمتر از دو گزینه دارد.',
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        examQuestions = loadedQuestions;
        answers = List<String?>.filled(examQuestions.length, null);
        isLoading = false;
      });

      loadCurrentText();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _showMessage(e.toString().replaceFirst('Exception: ', ''));

        Navigator.pop(context, false);
      });
    }
  }

  // =====================================================
  // CURRENT QUESTION
  // =====================================================

  Map<String, dynamic> get currentQuestionData {
    return examQuestions[currentQuestion];
  }

  void selectAnswer(String answer) {
    setState(() {
      answers[currentQuestion] = answer;
    });
  }

  void selectProjectAnswer(String answer) {
    setState(() {
      if (answer == 'خیر') {
        answers[currentQuestion] = 'خیر';
        projectController.clear();
      } else {
        answers[currentQuestion] = 'بلی';
      }
    });
  }

  void updateTextAnswer(String value) {
    answers[currentQuestion] = value;
  }

  String? getCurrentAnswer() {
    final String type = currentQuestionData['type'].toString();

    if (type == 'number' || type == 'text') {
      final value = textController.text.trim();
      return value.isEmpty ? null : value;
    }

    if (type == 'project') {
      final selected = answers[currentQuestion];

      if (selected == null) return null;

      if (selected == 'خیر') return 'خیر';

      if (selected == 'بلی' || selected.startsWith('بلی - ')) {
        final projectName = projectController.text.trim();

        if (projectName.isEmpty) return null;

        return 'بلی - $projectName';
      }

      return null;
    }

    return answers[currentQuestion];
  }

  void loadCurrentText() {
    if (examQuestions.isEmpty) return;

    final type = currentQuestionData['type'];

    if (type == 'number' || type == 'text') {
      textController.text = answers[currentQuestion] ?? '';

      textController.selection = TextSelection.fromPosition(
        TextPosition(offset: textController.text.length),
      );
    }

    if (type == 'project') {
      final answer = answers[currentQuestion];

      if (answer != null && answer.startsWith('بلی - ')) {
        projectController.text = answer.substring(6);
      } else {
        projectController.clear();
      }
    }
  }

  // =====================================================
  // NAVIGATION
  // =====================================================

  Future<void> nextQuestion() async {
    if (isSaving || examQuestions.isEmpty) return;

    final answer = getCurrentAnswer();

    if (answer == null || answer.trim().isEmpty) {
      _showMessage(
        currentQuestionData['type'] == 'project'
            ? 'اگر بلی را انتخاب می‌کنید، نام پروژه را نیز بنویسید'
            : 'لطفاً پاسخ این سوال را وارد کنید',
      );
      return;
    }

    answers[currentQuestion] = answer;

    if (currentQuestion < examQuestions.length - 1) {
      setState(() {
        currentQuestion++;
      });

      loadCurrentText();
      return;
    }

    await submitEvaluation();
  }

  void previousQuestion() {
    if (currentQuestion == 0 || isSaving) return;

    final answer = getCurrentAnswer();

    if (answer != null) {
      answers[currentQuestion] = answer;
    }

    setState(() {
      currentQuestion--;
    });

    loadCurrentText();
  }

  // =====================================================
  // SAVE EVALUATION
  // =====================================================

  Future<void> submitEvaluation() async {
    if (isSaving || examQuestions.isEmpty) return;

    final currentAnswer = getCurrentAnswer();

    if (currentAnswer == null || currentAnswer.trim().isEmpty) {
      _showMessage('لطفاً پاسخ سوال را وارد کنید');
      return;
    }

    answers[currentQuestion] = currentAnswer;

    for (int i = 0; i < answers.length; i++) {
      if (answers[i] == null || answers[i]!.trim().isEmpty) {
        setState(() {
          currentQuestion = i;
        });

        loadCurrentText();

        _showMessage('لطفاً به تمام سوالات پاسخ دهید');
        return;
      }
    }

    final cleanStudentName = widget.studentName.trim();

    if (cleanStudentName.isEmpty) {
      _showMessage('نام شاگرد نمی‌تواند خالی باشد');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // جلوگیری از ثبت ارزیابی تکراری.
      final existing = await IsarService.getStudentEvaluation(
        widget.classModel.id,
        cleanStudentName,
      );

      if (existing != null) {
        throw Exception(
          'این شاگرد قبلاً ارزیابی شده است و نتیجه قبلی تغییر نمی‌کند.',
        );
      }

      // ذخیره نسخه مستقل سوالات همین ارزیابی.
      final String snapshotJson = encodeSnapshot(examQuestions);

      final evaluation = EvaluationModel()
        ..classId = widget.classModel.id
        ..className = widget.classModel.className
        ..studentName = cleanStudentName
        ..answers = answers.map((answer) => answer ?? '').toList()
        ..totalQuestions = examQuestions.length
        ..correctAnswers = 0
        ..evaluatedAt = DateTime.now()
        ..questionSnapshotJson = snapshotJson;

      await IsarService.saveEvaluation(evaluation);

      if (!mounted) return;

      _showMessage('ارزیابی با موفقیت ذخیره شد');

      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('Save Evaluation Error: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.vazirmatn(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =====================================================
  // QUESTION CARD
  // =====================================================

  Widget _buildQuestionCard() {
    final String question = currentQuestionData['question'].toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        question,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.vazirmatn(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.8,
        ),
      ),
    );
  }

  // =====================================================
  // OPTION CARD
  // =====================================================

  Widget _buildOptionCard(
    String option,
    int index, {
    bool isProject = false,
  }) {
    final selectedAnswer = answers[currentQuestion];

    final bool selected = isProject
        ? (option == 'بلی'
            ? selectedAnswer == 'بلی' ||
                (selectedAnswer?.startsWith('بلی - ') ?? false)
            : selectedAnswer == option)
        : selectedAnswer == option;

    final String letter = String.fromCharCode(65 + index);

    return GestureDetector(
      onTap: () {
        if (isProject) {
          selectProjectAnswer(option);
        } else {
          selectAnswer(option);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAE7FF) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? primaryColor : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? primaryColor
                    : const Color(0xFFF1F3F5),
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: GoogleFonts.vazirmatn(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.vazirmatn(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? primaryColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // TEXT FIELD
  // =====================================================

  Widget _buildTextField() {
    final String type = currentQuestionData['type'].toString();
    final bool number = type == 'number';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: textController,
        keyboardType: number
            ? TextInputType.number
            : TextInputType.multiline,
        maxLines: number ? 1 : 5,
        textDirection: TextDirection.rtl,
        onChanged: updateTextAnswer,
        decoration: InputDecoration(
          hintText: number ? 'تعداد را وارد کنید' : 'پاسخ خود را بنویسید',
          hintStyle: GoogleFonts.vazirmatn(
            color: Colors.grey.shade500,
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: GoogleFonts.vazirmatn(fontSize: 14),
      ),
    );
  }

  // =====================================================
  // PROJECT QUESTION
  // =====================================================

  Widget _buildProjectQuestion() {
    final selected = answers[currentQuestion];

    final bool yesSelected =
        selected == 'بلی' ||
        (selected?.startsWith('بلی - ') ?? false);

    return Column(
      children: [
        _buildOptionCard('بلی', 0, isProject: true),
        _buildOptionCard('خیر', 1, isProject: true),
        if (yesSelected) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: projectController,
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                final projectName = value.trim();

                answers[currentQuestion] = projectName.isEmpty
                    ? 'بلی'
                    : 'بلی - $projectName';
              },
              decoration: InputDecoration(
                hintText: 'نام پروژه را بنویسید',
                hintStyle: GoogleFonts.vazirmatn(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.vazirmatn(fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  // =====================================================
  // LOADING SCREEN
  // =====================================================

  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'ارزیابی شاگرد',
              style: GoogleFonts.vazirmatn(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: _buildLoadingScreen(),
        ),
      );
    }

    if (examQuestions.isEmpty || alreadyEvaluated) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: _buildLoadingScreen(),
        ),
      );
    }

    final String type = currentQuestionData['type'].toString();

    final options = (currentQuestionData['options'] as List)
        .map((option) => option.toString())
        .toList();

    final double progress =
        (currentQuestion + 1) / examQuestions.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'ارزیابی شاگرد',
            style: GoogleFonts.vazirmatn(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.studentName,
                        style: GoogleFonts.vazirmatn(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${currentQuestion + 1}/${examQuestions.length}',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    primaryColor,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      _buildQuestionCard(),
                      const SizedBox(height: 16),
                      if (type == 'choice')
                        ...options.asMap().entries.map(
                          (entry) => _buildOptionCard(
                            entry.value,
                            entry.key,
                          ),
                        ),
                      if (type == 'number' || type == 'text')
                        _buildTextField(),
                      if (type == 'project')
                        _buildProjectQuestion(),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: currentQuestion > 0 && !isSaving
                            ? previousQuestion
                            : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'قبلی',
                          style: GoogleFonts.vazirmatn(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving ? null : nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size(0, 50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          isSaving
                              ? 'در حال ذخیره...'
                              : currentQuestion == examQuestions.length - 1
                                  ? 'ثبت ارزیابی'
                                  : 'بعدی',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
