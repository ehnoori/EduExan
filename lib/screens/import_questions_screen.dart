
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel_plus/excel_plus.dart' hide Border;
import 'package:path_provider/path_provider.dart';

import '../database/isar_service.dart';
import '../models/question_model.dart';

class ImportQuestionsScreen extends StatefulWidget {
  const ImportQuestionsScreen({super.key});

  @override
  State<ImportQuestionsScreen> createState() =>
      _ImportQuestionsScreenState();
}

class _ImportQuestionsScreenState extends State<ImportQuestionsScreen> {
  static const Color primaryColor = Color(0xFF1565E8);
  static const Color backgroundColor = Color(0xFFF1F3F3);

  static const String savedFileName = 'questions.xlsx';
  static const String tempFileName = 'questions_temp.xlsx';
  static const String backupFileName = 'questions_backup.xlsx';

  String? fileName;
  String? sheetName;

  List<List<String>> excelRows = [];
  List<int>? selectedExcelBytes;

  bool isLoading = false;
  bool hasSavedFile = false;

  @override
  void initState() {
    super.initState();
    loadSavedFile();
  }

  // مسیر فایل اصلی
  Future<File> getSavedFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$savedFileName');
  }

  // خواندن فایل Excel و آماده‌سازی پیش‌نمایش
  Future<void> readExcelBytes(
    List<int> bytes, {
    required String name,
  }) async {
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception('فایل Excel خالی است.');
    }

    final firstSheetName = excel.tables.keys.first;
    final sheet = excel.tables[firstSheetName];

    if (sheet == null) {
      throw Exception('صفحه Excel پیدا نشد.');
    }

    final rows = sheet.rows.map((row) {
      return row.map((cell) {
        return cell?.value?.toString() ?? '';
      }).toList();
    }).where((row) {
      return row.any((cell) => cell.trim().isNotEmpty);
    }).toList();

    if (rows.isEmpty) {
      throw Exception('هیچ اطلاعاتی در فایل Excel وجود ندارد.');
    }

    if (!mounted) return;

    setState(() {
      fileName = name;
      sheetName = firstSheetName;
      excelRows = rows;
      selectedExcelBytes = List<int>.from(bytes);
    });
  }

  // ذخیره امن فایل در حافظه دائمی برنامه
  Future<void> saveFilePermanently(List<int> bytes) async {
    final directory = await getApplicationDocumentsDirectory();

    final finalFile = File('${directory.path}/$savedFileName');
    final tempFile = File('${directory.path}/$tempFileName');
    final backupFile = File('${directory.path}/$backupFileName');

    bool oldFileMoved = false;
    bool newFileInstalled = false;

    try {
      await tempFile.writeAsBytes(bytes, flush: true);

      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      if (await finalFile.exists()) {
        await finalFile.rename(backupFile.path);
        oldFileMoved = true;
      }

      await tempFile.rename(finalFile.path);
      newFileInstalled = true;

      if (oldFileMoved && await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      try {
        if (newFileInstalled && await finalFile.exists()) {
          await finalFile.delete();
        }

        if (oldFileMoved && await backupFile.exists()) {
          await backupFile.rename(finalFile.path);
        }
      } catch (restoreError) {
        debugPrint('RESTORE FILE ERROR: $restoreError');
      }

      rethrow;
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  // بازیابی فایل هنگام ورود دوباره به صفحه
  Future<void> loadSavedFile() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final file = await getSavedFile();

      if (!await file.exists()) {
        if (mounted) {
          setState(() {
            hasSavedFile = false;
            isLoading = false;
          });
        }
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('فایل ذخیره‌شده خالی است.');
      }

      await readExcelBytes(
        bytes,
        name: savedFileName,
      );

      if (!mounted) return;

      setState(() {
        hasSavedFile = true;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('LOAD SAVED FILE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        hasSavedFile = false;
        isLoading = false;
      });

      showMessage('خطا در خواندن فایل ذخیره‌شده: $e');
    }
  }

  // انتخاب فایل Excel
  Future<void> pickExcelFile() async {
    if (isLoading) return;

    try {
      setState(() => isLoading = true);

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

      debugPrint('Selected file: ${selectedFile.name}');
      debugPrint('File path: ${selectedFile.path}');

      final bytes = await selectedFile.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('محتوای فایل خالی است.');
      }

      // خواندن فایل
      await readExcelBytes(
        bytes,
        name: selectedFile.name,
      );

      // بررسی سوالات پیش از ذخیره فایل جدید
      parseQuestions();

      // ذخیره دائمی فایل پس از اعتبارسنجی
      await saveFilePermanently(bytes);

      if (!mounted) return;

      setState(() {
        fileName = selectedFile.name;
        selectedExcelBytes = List<int>.from(bytes);
        hasSavedFile = true;
        isLoading = false;
      });

      showMessage('فایل Excel انتخاب و در حافظه برنامه ذخیره شد.');
    } catch (e, stackTrace) {
      debugPrint('PICK EXCEL ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => isLoading = false);

      showMessage('خطا در انتخاب یا ذخیره فایل: $e');
    }
  }

  // تبدیل نوع سوال
  String normalizeType(String value) {
    final type = normalizeHeader(value);

    switch (type) {
      case 'choice':
      case 'multiple choice':
      case 'چندگزینه‌ای':
      case 'چند گزینه‌ای':
      case 'چندگزینه ای':
      case 'چند گزینه ای':
        return 'choice';

      case 'number':
      case 'عدد':
      case 'عددی':
        return 'number';

      case 'text':
      case 'تشریحی':
        return 'text';

      case 'project':
      case 'پروژه':
        return 'project';

      default:
        return '';
    }
  }

  // یکسان‌سازی عنوان ستون‌ها
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

  // تبدیل ردیف‌های Excel به QuestionModel
  List<QuestionModel> parseQuestions() {
    if (excelRows.length < 2) {
      throw Exception(
        'فایل باید عنوان ستون‌ها و حداقل یک سوال داشته باشد.',
      );
    }

    final headers = excelRows.first.map(normalizeHeader).toList();

    int findColumn(List<String> names) {
      return headers.indexWhere(
        (header) => names.contains(header),
      );
    }

    // ستون سوال
    final questionIndex = findColumn([
      'question',
      'سوال',
      'سؤال',
    ]);

    // ستون نوع سوال
    final typeIndex = findColumn([
      'type',
      'نوع',
      'نوع سوال',
      'نوع سؤال',
    ]);

    // ستون پاسخ صحیح
    final correctIndex = findColumn([
      'correct answer',
      'correctanswer',
      'پاسخ درست',
      'پاسخ صحیح',
    ]);

    if (questionIndex == -1 || typeIndex == -1) {
      throw Exception(
        'ستون سوال یا نوع سوال در فایل پیدا نشد. '
        'عنوان ستون‌ها: ${headers.join(', ')}',
      );
    }

    // پیدا کردن ستون‌های گزینه‌ها
    final optionColumns = <MapEntry<int, String>>[];

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];

      final isOption = RegExp(
        r'^(option\s*[a-z0-9]+|گزینه\s*[a-z0-9]+)$',
      ).hasMatch(header);

      if (isOption) {
        optionColumns.add(MapEntry(i, header));
      }
    }

    optionColumns.sort((a, b) => a.key.compareTo(b.key));

    String getCell(List<String> row, int index) {
      if (index < 0 || index >= row.length) return '';
      return row[index].trim();
    }

    final importedQuestions = <QuestionModel>[];

    for (int i = 1; i < excelRows.length; i++) {
      final row = excelRows[i];

      final questionText = getCell(row, questionIndex);
      final type = normalizeType(getCell(row, typeIndex));

      if (questionText.isEmpty) continue;

      if (type.isEmpty) {
        throw Exception(
          'نوع سوال در ردیف ${i + 1} معتبر نیست: '
          '${getCell(row, typeIndex)}',
        );
      }

      // خواندن گزینه‌ها
      final options = <String>[];

      for (final column in optionColumns) {
        final value = getCell(row, column.key);

        if (value.isNotEmpty) {
          options.add(value);
        }
      }

      if (type == 'choice' && options.length < 2) {
        throw Exception(
          'سوال چندگزینه‌ای در ردیف ${i + 1} '
          'حداقل دو گزینه نیاز دارد.',
        );
      }

      if (type == 'project' && options.isEmpty) {
        options.addAll(['بلی', 'خیر']);
      }

      // خواندن پاسخ صحیح
      String? correctAnswer;

      final correctValue = getCell(row, correctIndex);

      if (correctValue.isNotEmpty) {
        final upper = correctValue.toUpperCase();

        final letterIndex = upper.codeUnitAt(0) - 65;

        final isSingleLetter = upper.length == 1 &&
            letterIndex >= 0 &&
            letterIndex < options.length;

        if (isSingleLetter) {
          correctAnswer = options[letterIndex];
        } else if (options.contains(correctValue)) {
          correctAnswer = correctValue;
        } else {
          throw Exception(
            'پاسخ صحیح در ردیف ${i + 1} معتبر نیست: '
            '$correctValue',
          );
        }
      }

      final question = QuestionModel()
        ..question = questionText
        ..type = type
        ..options = options
        ..correctAnswer = correctAnswer;

      importedQuestions.add(question);
    }

    if (importedQuestions.isEmpty) {
      throw Exception('هیچ سوال معتبری پیدا نشد.');
    }

    return importedQuestions;
  }

  // ذخیره سوالات در دیتابیس Isar
  Future<void> saveImportedQuestions() async {
    if (isLoading) return;

    if (selectedExcelBytes == null ||
        selectedExcelBytes!.isEmpty) {
      showMessage('ابتدا یک فایل Excel انتخاب کنید.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final importedQuestions = parseQuestions();

      await IsarService.saveQuestions(importedQuestions);

      if (!mounted) return;

      setState(() {
        hasSavedFile = true;
        isLoading = false;
      });

      showMessage(
        '${importedQuestions.length} سوال با موفقیت در برنامه ذخیره شد.',
      );
    } catch (e, stackTrace) {
      debugPrint('SAVE QUESTIONS ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => isLoading = false);

      showMessage('خطا در ذخیره سوالات: $e');
    }
  }

  // حذف فایل و بانک عمومی سوالات
  Future<void> deleteCurrentFile() async {
    if (isLoading) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'حذف فایل',
            style: GoogleFonts.vazirmatn(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'فایل Excel و بانک سوالات جدید حذف می‌شوند؛ '
            'اما نتایج ارزیابی‌های قبلی محفوظ می‌مانند. ادامه می‌دهید؟',
            style: GoogleFonts.vazirmatn(fontSize: 13),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      // فقط بانک عمومی سوالات حذف می‌شود.
      // ارزیابی‌های قبلی حذف نمی‌شوند.
      await IsarService.deleteAllQuestions();

      final directory = await getApplicationDocumentsDirectory();

      final files = [
        File('${directory.path}/$savedFileName'),
        File('${directory.path}/$tempFileName'),
        File('${directory.path}/$backupFileName'),
      ];

      for (final file in files) {
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (!mounted) return;

      setState(() {
        fileName = null;
        sheetName = null;
        excelRows = [];
        selectedExcelBytes = null;
        hasSavedFile = false;
        isLoading = false;
      });

      showMessage(
        'فایل و بانک سوالات حذف شدند. نتایج امتحان‌های قبلی محفوظ‌اند.',
      );
    } catch (e, stackTrace) {
      debugPrint('DELETE FILE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => isLoading = false);

      showMessage('خطا در حذف فایل: $e');
    }
  }

  // نمایش پیام
  void showMessage(String message) {
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

  // ساخت صفحه
  @override
  Widget build(BuildContext context) {
    final int maxColumns = excelRows.isEmpty
        ? 0
        : excelRows.map((row) => row.length).reduce(
              (a, b) => a > b ? a : b,
            );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'وارد کردن سوالات',
            style: GoogleFonts.vazirmatn(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF172B5B),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // کارت انتخاب فایل
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E9B57)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          size: 40,
                          color: Color(0xFF2E9B57),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'فایل Excel سوالات را انتخاب کنید',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.vazirmatn(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF172B5B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'فایل باید با فرمت XLSX باشد.',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : pickExcelFile,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: Text(
                            hasSavedFile
                                ? 'انتخاب فایل جدید'
                                : 'انتخاب فایل Excel',
                            style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // نمایش فایل انتخاب‌شده
                if (fileName != null && !isLoading) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'فایل انتخاب‌شده',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.description_rounded,
                              color: Color(0xFF2E9B57),
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                fileName!,
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // const Divider(height: 24),
                        // Text(
                        //   'نام صفحه: $sheetName',
                        //   style: GoogleFonts.vazirmatn(fontSize: 13),
                        // ),
                        // Text(
                        //   'تعداد ردیف‌ها: ${excelRows.length}',
                        //   style: GoogleFonts.vazirmatn(fontSize: 13),
                        // ),
                        if (hasSavedFile) ...[
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Color(0xFF2E9B57),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'فایل در حافظه دائمی برنامه ذخیره شده است.',
                                  style: TextStyle(
                                    color: Color(0xFF2E9B57),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: OutlinedButton.icon(
                            onPressed:
                                isLoading ? null : deleteCurrentFile,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: Text(
                              'حذف فایل و سوالات واردشده',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // عنوان پیش‌نمایش
                  Text(
                    'پیش‌نمایش اطلاعات',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF172B5B),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // جدول پیش‌نمایش Excel
                  if (excelRows.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFEAF1FC),
                          ),
                          columns: List.generate(
                            maxColumns,
                            (index) => DataColumn(
                              label: Text(
                                'ستون ${index + 1}',
                                style: GoogleFonts.vazirmatn(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          rows: excelRows.map((row) {
                            return DataRow(
                              cells: List.generate(
                                maxColumns,
                                (index) => DataCell(
                                  Text(
                                    index < row.length ? row[index] : '',
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ذخیره سوالات در دیتابیس
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                          isLoading ? null : saveImportedQuestions,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        'ذخیره سوالات در برنامه',
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E9B57),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
