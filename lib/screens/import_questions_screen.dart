import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
//import 'package:excel_plus/excel_plus.dart' hide Border;
import 'package:excel_plus/excel_plus.dart' hide Border, TextSpan;
import 'package:path_provider/path_provider.dart';

import '../database/isar_service.dart';
import '../models/question_model.dart';

class QuestionBank {
  final String id;
  final String name;
  final String storedName;
  final int questionCount;
  final String createdAt;

  const QuestionBank({
    required this.id,
    required this.name,
    required this.storedName,
    required this.questionCount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'storedName': storedName,
    'questionCount': questionCount,
    'createdAt': createdAt,
  };

  factory QuestionBank.fromJson(Map<String, dynamic> json) {
    return QuestionBank(
      id: json['id'].toString(),
      name: json['name'].toString(),
      storedName: json['storedName'].toString(),
      questionCount: json['questionCount'] as int? ?? 0,
      createdAt: json['createdAt'].toString(),
    );
  }
}

class ImportQuestionsScreen extends StatefulWidget {
  const ImportQuestionsScreen({super.key});

  @override
  State<ImportQuestionsScreen> createState() => _ImportQuestionsScreenState();
}

class _ImportQuestionsScreenState extends State<ImportQuestionsScreen> {
  static const Color primaryColor = Color(0xFF1565E8);
  static const Color navyColor = Color(0xFF172B5B);
  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color successColor = Color(0xFF219653);
  static const Color dangerColor = Color(0xFFE53935);
  static const Color borderColor = Color(0xFFE5EAF2);

  static const String folderName = 'question_banks';
  static const String manifestName = 'question_banks.json';
  static const String activeBankName = 'active_question_bank.txt';

  List<QuestionBank> banks = [];

  String? selectedBankId;
  String? activeBankId;

  List<List<String>> excelRows = [];

  bool isLoading = false;
  bool showPreview = false;

  @override
  void initState() {
    super.initState();
    loadBanks();
  }

  TextStyle get titleStyle => GoogleFonts.vazirmatn(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: navyColor,
  );

  TextStyle get normalStyle =>
      GoogleFonts.vazirmatn(fontSize: 12, color: const Color(0xFF64748B));

  BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: navyColor.withValues(alpha: 0.035),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );

  QuestionBank? get selectedBank {
    for (final bank in banks) {
      if (bank.id == selectedBankId) return bank;
    }
    return null;
  }

  QuestionBank? get activeBank {
    for (final bank in banks) {
      if (bank.id == activeBankId) return bank;
    }
    return null;
  }

  Future<Directory> getBankDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final directory = Directory('${appDirectory.path}/$folderName');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<File> getManifestFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$manifestName');
  }

  Future<File> getActiveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$activeBankName');
  }

  Future<File> getBankFile(QuestionBank bank) async {
    final directory = await getBankDirectory();
    return File('${directory.path}/${bank.storedName}');
  }

  Future<void> saveManifest() async {
    final file = await getManifestFile();

    final jsonData = banks.map((bank) => bank.toJson()).toList();

    await file.writeAsString(jsonEncode(jsonData), flush: true);
  }

  // LOAD FILES

  Future<void> loadBanks() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final manifest = await getManifestFile();

      if (await manifest.exists()) {
        final content = await manifest.readAsString();

        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content) as List;

          banks = decoded.map((item) {
            return QuestionBank.fromJson(Map<String, dynamic>.from(item));
          }).toList();
        }
      }

      final validBanks = <QuestionBank>[];

      for (final bank in banks) {
        final file = await getBankFile(bank);

        if (await file.exists()) {
          validBanks.add(bank);
        }
      }

      banks = validBanks;

      final activeFile = await getActiveFile();

      if (await activeFile.exists()) {
        final value = (await activeFile.readAsString()).trim();

        if (banks.any((bank) => bank.id == value)) {
          activeBankId = value;
        } else {
          activeBankId = null;
          await activeFile.delete();
        }
      }

      if (selectedBankId == null ||
          !banks.any((bank) => bank.id == selectedBankId)) {
        selectedBankId =
            activeBankId ?? (banks.isNotEmpty ? banks.first.id : null);
      }

      await saveManifest();
      await loadSelectedPreview();

      if (!mounted) return;

      setState(() {
        isLoading = false;
        showPreview = false;
      });
    } catch (e, stackTrace) {
      debugPrint('LOAD FILES ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => isLoading = false);

      showMessage('خطا در بارگذاری فایل‌ها: $e');
    }
  }

  // READ EXCEL

  List<List<String>> readExcelRows(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception('فایل Excel خالی است.');
    }

    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];

    if (sheet == null) {
      throw Exception('صفحه Excel پیدا نشد.');
    }

    final rows = sheet.rows
        .map((row) {
          return row.map((cell) {
            return cell?.value?.toString() ?? '';
          }).toList();
        })
        .where((row) {
          return row.any((cell) => cell.trim().isNotEmpty);
        })
        .toList();

    if (rows.isEmpty) {
      throw Exception('هیچ اطلاعاتی در فایل Excel وجود ندارد.');
    }

    return rows;
  }

  Future<void> loadSelectedPreview() async {
    final bank = selectedBank;

    if (bank == null) {
      excelRows = [];
      return;
    }

    final file = await getBankFile(bank);

    if (!await file.exists()) {
      excelRows = [];
      return;
    }

    final bytes = await file.readAsBytes();

    excelRows = readExcelRows(bytes);
  }

  // NORMALIZE HEADERS

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

  // PARSE QUESTIONS

  List<QuestionModel> parseQuestions(List<List<String>> rows) {
    if (rows.length < 2) {
      throw Exception('فایل باید عنوان ستون‌ها و حداقل یک سوال داشته باشد.');
    }

    final headers = rows.first.map(normalizeHeader).toList();

    final questionIndex = headers.indexWhere(
      (header) => ['question', 'سوال', 'سؤال'].contains(header),
    );

    final correctIndex = headers.indexWhere(
      (header) => [
        'correct answer',
        'correctanswer',
        'پاسخ درست',
        'پاسخ صحیح',
      ].contains(header),
    );

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

      if (questionText.isEmpty && correctAnswer.isEmpty) {
        continue;
      }

      if (questionText.isEmpty) {
        throw Exception('متن سوال در ردیف ${i + 1} خالی است.');
      }

      if (correctAnswer.isEmpty) {
        throw Exception('پاسخ سوال در ردیف ${i + 1} خالی است.');
      }

      final question = QuestionModel()
        ..question = questionText
        ..type = 'text'
        ..options = []
        ..correctAnswer = correctAnswer;

      importedQuestions.add(question);
    }

    if (importedQuestions.isEmpty) {
      throw Exception('هیچ سوال معتبری پیدا نشد.');
    }

    return importedQuestions;
  }

  // IMPORT EXCEL FILE

  Future<void> pickExcelFile() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final PlatformFile? selectedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (selectedFile == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final bytes = await selectedFile.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('فایل انتخاب‌شده خالی است.');
      }

      final rows = readExcelRows(bytes);
      final questions = parseQuestions(rows);

      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final storedName = 'bank_$id.xlsx';

      final directory = await getBankDirectory();

      final savedFile = File('${directory.path}/$storedName');

      await savedFile.writeAsBytes(bytes, flush: true);

      final bank = QuestionBank(
        id: id,
        name: selectedFile.name,
        storedName: storedName,
        questionCount: questions.length,
        createdAt: DateTime.now().toIso8601String(),
      );

      banks.insert(0, bank);

      await saveManifest();

      if (!mounted) return;

      setState(() {
        selectedBankId = bank.id;
        excelRows = rows;
        showPreview = false;
        isLoading = false;
      });

      showMessage('${questions.length} سوال با موفقیت وارد شد.');
    } catch (e, stackTrace) {
      debugPrint('IMPORT EXCEL ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => isLoading = false);

      showMessage('خطا در وارد کردن فایل: $e');
    }
  }

  // ACTIVATE FILE

  Future<void> selectBank(QuestionBank bank) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      selectedBankId = bank.id;
      showPreview = false;
    });

    try {
      final file = await getBankFile(bank);

      if (!await file.exists()) {
        throw Exception('فایل Excel پیدا نشد.');
      }

      final bytes = await file.readAsBytes();

      final rows = readExcelRows(bytes);
      final questions = parseQuestions(rows);

      await IsarService.saveQuestions(questions);

      final activeFile = await getActiveFile();

      await activeFile.writeAsString(bank.id, flush: true);

      if (!mounted) return;

      setState(() {
        activeBankId = bank.id;
        selectedBankId = bank.id;
        excelRows = rows;
        isLoading = false;
        showPreview = false;
      });

      showMessage(
        'فایل «${bank.name}» فعال شد. '
        '${questions.length} سوال برای امتحان آماده است.',
      );
    } catch (e, stackTrace) {
      debugPrint('ACTIVATE FILE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => isLoading = false);

      showMessage('فعال‌سازی فایل ناموفق بود: $e');
    }
  }

  // SHOW / HIDE QUESTIONS

  Future<void> toggleSelectedPreview() async {
    if (isLoading) return;

    if (showPreview) {
      setState(() {
        showPreview = false;
      });
      return;
    }

    final bank = selectedBank;

    if (bank == null) {
      showMessage('ابتدا یک فایل را انتخاب کنید.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await loadSelectedPreview();

      if (!mounted) return;

      if (excelRows.isEmpty) {
        setState(() {
          isLoading = false;
          showPreview = false;
        });

        showMessage('سوالی برای نمایش وجود ندارد.');
        return;
      }

      setState(() {
        isLoading = false;
        showPreview = true;
      });
    } catch (e, stackTrace) {
      debugPrint('PREVIEW ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        isLoading = false;
        showPreview = false;
      });

      showMessage('خطا در نمایش سوالات: $e');
    }
  }

  // DELETE FILE

  Future<void> deleteBank(QuestionBank bank) async {
    if (isLoading) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 8,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: dangerColor.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: dangerColor,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 17),

                  Text(
                    'حذف فایل سوالات',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: navyColor,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'آیا مطمئن هستید که می‌خواهید این فایل را حذف کنید؟',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12,
                      height: 1.9,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.description_rounded,
                          color: primaryColor,
                          size: 23,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          bank.name,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: navyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'فایل‌های دیگر و نتایج ارزیابی شاگردان حذف نمی‌شوند.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 11,
                      height: 1.8,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: navyColor,
                              side: const BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'انصراف',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.vazirmatn(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dangerColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Expanded(
                                  child: Text(
                                    'حذف فایل',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      if (activeBankId == bank.id) {
        await IsarService.deleteAllQuestions();

        final activeFile = await getActiveFile();

        if (await activeFile.exists()) {
          await activeFile.delete();
        }

        activeBankId = null;
      }

      final file = await getBankFile(bank);

      if (await file.exists()) {
        await file.delete();
      }

      banks.removeWhere((item) => item.id == bank.id);

      if (selectedBankId == bank.id) {
        selectedBankId = banks.isNotEmpty ? banks.first.id : null;
      }

      await saveManifest();
      await loadSelectedPreview();

      if (!mounted) return;

      setState(() {
        showPreview = false;
        isLoading = false;
      });

      showMessage('فایل سوالات با موفقیت حذف شد.');
    } catch (e, stackTrace) {
      debugPrint('DELETE FILE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => isLoading = false);

      showMessage('خطا در حذف فایل: $e');
    }
  }

  // MESSAGE

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.vazirmatn(fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: navyColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  // MAIN ACTION BUTTON

  Widget actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    double height = 48,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: GoogleFonts.vazirmatn(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }

  // CARD ACTION BUTTON

  Widget cardActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 43,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: GoogleFonts.vazirmatn(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 17),
          ],
        ),
      ),
    );
  }

  // FILE CARD

  Widget buildBankCard(QuestionBank bank) {
    final isSelected = selectedBankId == bank.id;
    final isActive = activeBankId == bank.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? primaryColor : borderColor,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: primaryColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('${bank.questionCount} سوال', style: normalStyle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isActive)
                _statusBadge(text: 'فعال', color: successColor)
              else if (isSelected)
                _statusBadge(text: 'انتخاب‌شده', color: primaryColor)
              else
                Icon(
                  Icons.radio_button_off_rounded,
                  color: Colors.grey.shade400,
                ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: cardActionButton(
                  text: isActive ? 'انتخاب شده' : 'انتخاب کردن',
                  icon: Icons.check_box_rounded,
                  color: successColor,
                  onPressed: isLoading ? null : () => selectBank(bank),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: cardActionButton(
                  text: 'حذف',
                  icon: Icons.delete_outline_rounded,
                  color: dangerColor,
                  onPressed: isLoading ? null : () => deleteBank(bank),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STATUS BADGE

  Widget _statusBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.vazirmatn(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // QUESTIONS PREVIEW

  Widget buildPreview() {
    if (excelRows.isEmpty) {
      return const SizedBox.shrink();
    }

    final headers = excelRows.first.map(normalizeHeader).toList();

    final questionIndex = headers.indexWhere(
      (header) => ['question', 'سوال', 'سؤال'].contains(header),
    );

    final answerIndex = headers.indexWhere(
      (header) => [
        'correct answer',
        'correctanswer',
        'پاسخ درست',
        'پاسخ صحیح',
      ].contains(header),
    );

    if (questionIndex == -1 || answerIndex == -1) {
      return const SizedBox.shrink();
    }

    String getCell(List<String> row, int index) {
      if (index < 0 || index >= row.length) return '';
      return row[index].trim();
    }

    final questionRows = excelRows.skip(1).where((row) {
      return getCell(row, questionIndex).isNotEmpty;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz_rounded, color: primaryColor, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text('سوالات فایل انتخاب‌شده', style: titleStyle),
              ),
              Text(
                '${questionRows.length} سوال',
                style: GoogleFonts.vazirmatn(
                  fontSize: 10,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ...List.generate(questionRows.length, (index) {
            final row = questionRows[index];

            final question = getCell(row, questionIndex);
            final answer = getCell(row, answerIndex);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${index + 1}. $question',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: navyColor,
                      ),
                    ),
                    TextSpan(
                      text: ' ـ ',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    TextSpan(
                      text: answer,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: successColor,
                      ),
                    ),
                  ],
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            );
          }),
        ],
      ),
    );
  }

  // MAIN UI

  @override
  Widget build(BuildContext context) {
    final bank = selectedBank;
    final currentActiveBank = activeBank;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
      appBar: AppBar(
  backgroundColor: backgroundColor,
  elevation: 0,
  centerTitle: true,
  leading: IconButton(
    onPressed: () => Navigator.pop(context),
    icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF263238),
              size: 20,
            ),
  ),
),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ADD EXCEL FILE

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: cardDecoration,
                  child: Column(
                    children: [
                      // Image.asset(
                      //   'assets/images/a_clean_modern_high_resolution_vector_3d_style_e.png',
                      //   height: 115,
                      //   fit: BoxFit.contain,
                      // ),
                      // const SizedBox(height: 12),
                      Text(
                        'وارد کردن سوالات امتحان',
                        style: titleStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'فایل اکسل شامل سوالات امتحان را برای وارد کردن به برنامه انتخاب کنید.',
                        textAlign: TextAlign.center,
                        style: normalStyle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'فرمت قابل قبول فایل: Excel با پسوند .xlsx',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.vazirmatn(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 17),
                      actionButton(
                        text: 'انتخاب فایل اکسل',
                        icon: Icons.folder_open_rounded,
                        color: primaryColor,
                        onPressed: isLoading ? null : pickExcelFile,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ACTIVE FILE
                if (currentActiveBank != null) ...[
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: successColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: successColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: successColor,
                          size: 25,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'فایل انتخاب شده برای امتحان',
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 12,
                                  color: successColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentActiveBank.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: navyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // FILE LIST TITLE
                Row(
                  children: [
                    Text('فهرست فایل‌های سوالات', style: titleStyle),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${banks.length} فایل',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  ),

                // EMPTY STATE
                if (banks.isEmpty && !isLoading)
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: cardDecoration,
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_off_rounded,
                          size: 45,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text('هنوز فایلی وارد نشده است.', style: titleStyle),
                        const SizedBox(height: 5),
                        Text(
                          'برای شروع، یک فایل Excel انتخاب کنید.',
                          style: normalStyle,
                        ),
                      ],
                    ),
                  ),

                // FILE CARDS
                if (!isLoading) ...banks.map(buildBankCard),

                // SHOW / HIDE QUESTIONS
                if (bank != null && !isLoading) ...[
                  const SizedBox(height: 5),
                  actionButton(
                    text: showPreview
                        ? 'بستن سوالات'
                        : 'نمایش سوالات فایل انتخاب‌شده',
                    icon: showPreview
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: primaryColor,
                    onPressed: toggleSelectedPreview,
                  ),
                ],

                // PREVIEW
                if (showPreview && !isLoading) ...[
                  const SizedBox(height: 10),
                  buildPreview(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
