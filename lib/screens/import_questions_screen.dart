import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
class ImportQuestionsScreen extends StatefulWidget {
  const ImportQuestionsScreen({super.key});

  @override
  State<ImportQuestionsScreen> createState() => _ImportQuestionsScreenState();
}

class _ImportQuestionsScreenState extends State<ImportQuestionsScreen> {
  static const Color primaryColor = Color(0xFF1565E8);
  static const Color backgroundColor = Color(0xFFF1F3F3);

  String? fileName;
  String? sheetName;

  List<List<String>> excelRows = [];

  bool isLoading = false;

 
Future<void> pickExcelFile() async {
  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result.isEmpty) return;

    final file = result.first;
if (file.path == null) {
  showMessage('مسیر فایل پیدا نشد.');
  return;
}

final fileBytes = await File(file.path!).readAsBytes();

final excel = Excel.decodeBytes(fileBytes);

    if (excel.tables.isEmpty) {
      showMessage('فایل Excel خالی است.');
      setState(() => isLoading = false);
      return;
    }

    final firstSheetName = excel.tables.keys.first;
    final sheet = excel.tables[firstSheetName];

    if (sheet == null) {
      showMessage('صفحه Excel پیدا نشد.');
      setState(() => isLoading = false);
      return;
    }

    final rows = sheet.rows.map((row) {
      return row.map((cell) {
        return cell?.value?.toString() ?? '';
      }).toList();
    }).where((row) {
      return row.any((cell) => cell.trim().isNotEmpty);
    }).toList();

    if (!mounted) return;

    setState(() {
      fileName = file.name;
      sheetName = firstSheetName;
      excelRows = rows;
      isLoading = false;
    });

    showMessage('فایل با موفقیت خوانده شد.');

  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    showMessage('خطا در خواندن فایل Excel: $e');
  }
}


  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                // بخش انتخاب فایل
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
                            'انتخاب فایل Excel',
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

                if (isLoading) const Center(child: CircularProgressIndicator()),

                // اطلاعات فایل انتخاب‌شده
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
                                style: GoogleFonts.vazirmatn(fontSize: 13),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        Text(
                          'نام صفحه: $sheetName',
                          style: GoogleFonts.vazirmatn(fontSize: 13),
                        ),

                        Text(
                          'تعداد ردیف‌ها: ${excelRows.length}',
                          style: GoogleFonts.vazirmatn(fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // پیش‌نمایش اطلاعات Excel
                  Text(
                    'پیش‌نمایش اطلاعات',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF172B5B),
                    ),
                  ),

                  const SizedBox(height: 12),

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
                            excelRows
                                .map((e) => e.length)
                                .reduce((a, b) => a > b ? a : b),
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
                            final maxColumns = excelRows
                                .map((e) => e.length)
                                .reduce((a, b) => a > b ? a : b);

                            return DataRow(
                              cells: List.generate(
                                maxColumns,
                                (index) => DataCell(
                                  Text(
                                    index < row.length ? row[index] : '',
                                    style: GoogleFonts.vazirmatn(fontSize: 12),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
