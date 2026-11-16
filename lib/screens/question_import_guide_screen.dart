import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sample_excel_viewer_screen.dart';
import 'import_questions_screen.dart';

class QuestionImportGuideScreen extends StatelessWidget {
  const QuestionImportGuideScreen({super.key});

  static const Color primaryColor = Color(0xFF1565E8);
  static const Color textColor = Color(0xFF172B5B);
  static const Color secondaryColor = Color(0xFF68758A);
  static const Color backgroundColor = Color(0xFFF3F7FC);
  static const Color greenColor = Color(0xFF2E9B57);

  TextStyle get headingStyle => GoogleFonts.vazirmatn(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  TextStyle get descriptionStyle =>
      GoogleFonts.vazirmatn(fontSize: 12, height: 1.8, color: secondaryColor);

  // رفتن به صفحه وارد کردن سوالات
  void openImportScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ImportQuestionsScreen()),
    );
  }

  // باز کردن فایل اصلی Excel نمونه
  void openSampleFile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SampleExcelViewerScreen()),
    );
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
  leading: IconButton(
    onPressed: () => Navigator.pop(context),
    icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF263238),
              size: 20,
            ),
  ),

          title: Text(
            'راهنمای وارد کردن سوالات',
            style: GoogleFonts.vazirmatn(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 1, 8, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroduction(),

                      const SizedBox(height: 20),

                      _sectionTitle('انواع سوالات', Icons.quiz_rounded),

                      const SizedBox(height: 10),

                      _typeCard(
                        title: 'چندگزینه‌ای',
                        type: 'choice',
                        description: 'سوال با دو یا چند گزینه.',
                        icon: Icons.radio_button_checked_rounded,
                        color: primaryColor,
                      ),

                      _typeCard(
                        title: 'عددی',
                        type: 'number',
                        description: 'پاسخ به شکل عدد.',
                        icon: Icons.numbers_rounded,
                        color: const Color(0xFF6655D9),
                      ),

                      _typeCard(
                        title: 'تشریحی',
                        type: 'text',
                        description: 'پاسخ به شکل متن.',
                        icon: Icons.edit_note_rounded,
                        color: const Color(0xFFE67E22),
                      ),

                      _typeCard(
                        title: 'پروژه',
                        type: 'project',
                        description: 'پاسخ بلی یا خیر و نام پروژه.',
                        icon: Icons.assignment_rounded,
                        color: greenColor,
                      ),

                      const SizedBox(height: 20),

                      // فایل نمونه سوالات
                      _sectionTitle(
                        'فایل نمونه سوالات',
                        Icons.description_rounded,
                      ),

                      const SizedBox(height: 10),

                      _buildSampleFileCard(context),

                      const SizedBox(height: 20),

                      _sectionTitle('نکات مهم', Icons.checklist_rounded),

                      const SizedBox(height: 14),

                      _noteItem('فایل باید Excel با فرمت xlsx باشد.'),

                      _noteItem('هر سوال را در یک ردیف بنویسید.'),

                      _noteItem('نام ستون سوال باید Question باشد.'),

                      _noteItem(
                        'برای هر سوال، نوع آن را در ستون Type بنویسید.',
                      ),

                      _noteItem(
                        'برای سوال چندگزینه‌ای حداقل دو گزینه وارد کنید.',
                      ),

                      _noteItem('پاسخ درست را در ستون CorrectAnswer بنویسید.'),

                      const SizedBox(height: 12),

                      _warningBox(),
                    ],
                  ),
                ),
              ),

              _buildBottomButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // کارت فایل نمونه
  Widget _buildSampleFileCard(BuildContext context) {
    return InkWell(
      onTap: () => openSampleFile(context),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE8EEF6)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: greenColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.table_view_rounded,
                color: greenColor,
                size: 25,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نمونه سوالات EduExam', style: headingStyle),

                  const SizedBox(height: 5),

                  Text(
                    'برای مشاهده محتوای فایل کلیک کنید.',
                    style: descriptionStyle,
                  ),
                ],
              ),
            ),

            const Icon(Icons.visibility_rounded, color: primaryColor, size: 23),
          ],
        ),
      ),
    );
  }

  // معرفی
  Widget _buildIntroduction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565E8), Color(0xFF42A5F5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.16),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            'آماده‌سازی سوالات',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            'سوالات خود را در فایل Excel وارد کنید و سپس فایل را انتخاب نمایید.',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 12,
              height: 2,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  // عنوان بخش
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: primaryColor, size: 21),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            title,
            style: GoogleFonts.vazirmatn(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // کارت نوع سوال
  Widget _typeCard({
    required String title,
    required String type,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EEF6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 24),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: headingStyle)),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        type,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(description, style: descriptionStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // نکات مهم
  Widget _noteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: greenColor, size: 18),

          const SizedBox(width: 9),

          Expanded(child: Text(text, style: descriptionStyle)),
        ],
      ),
    );
  }

  // هشدار
  Widget _warningBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFFE2B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color.fromARGB(255, 234, 2, 2),
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
           child: Text(
  'قبل از انتخاب فایل، از درست بودن نام فایل و ترتیب ستون‌ها اطمینان حاصل کنید.',
  style: GoogleFonts.vazirmatn(
    fontSize: 11,
    height: 1.9,
    color: const Color.fromARGB(255, 251, 0, 0),
  ),
),
          ),
        ],
      ),
    );
  }

  // دکمه پایین
  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () => openImportScreen(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            'انتخاب فایل Excel',
            style: GoogleFonts.vazirmatn(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
