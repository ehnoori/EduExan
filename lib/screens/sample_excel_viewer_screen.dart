
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_document_viewer/spreadsheet.dart';

class SampleExcelViewerScreen extends StatefulWidget {
  const SampleExcelViewerScreen({super.key});

  @override
  State<SampleExcelViewerScreen> createState() =>
      _SampleExcelViewerScreenState();
}

class _SampleExcelViewerScreenState
    extends State<SampleExcelViewerScreen> {
  static const String filePath =
      'assets/files/eduexam_sample_questions.xlsx';

  late final SpreadsheetController controller;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    controller = SpreadsheetController();
    loadExcelFile();
  }

  Future<void> loadExcelFile() async {
    try {
      final data = await rootBundle.load(filePath);

      final Uint8List bytes = Uint8List.sublistView(data);

      // منتظر تکمیل خواندن و پردازش فایل می‌مانیم.
      await controller.loadBytes(bytes);

      if (!mounted) return;

      setState(() {
        isLoading = false;

        if (controller.status.name == 'failed') {
          errorMessage =
              'خواندن فایل Excel موفق نشد:\n${controller.error}';
        } else if (controller.sheetNames.isEmpty) {
          errorMessage = 'هیچ اطلاعاتی در فایل Excel پیدا نشد.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'باز کردن فایل Excel موفق نشد:\n$e';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172B5B),
        elevation: 0,
        title: const Text(
          'نمونه سوالات Excel',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1565E8),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Container(
                  color: Colors.white,
                  child: SpreadsheetView(
                    controller: controller,
                  ),
                ),
    );
  }
}
