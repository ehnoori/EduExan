import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'import_questions_screen.dart';

class QuestionImportGuideScreen extends StatelessWidget {
  const QuestionImportGuideScreen({super.key});

  static const Color primaryColor = Color(0xFF1565E8);
  static const Color textColor = Color(0xFF172B5B);
  static const Color secondaryColor = Color(0xFF68758A);
  static const Color backgroundColor = Color(0xFFF3F7FC);
  static const Color greenColor = Color(0xFF2E9B57);

  // استایل عنوان‌ها
  TextStyle get headingStyle => GoogleFonts.vazirmatn(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: textColor,
      );

  // استایل توضیحات
  TextStyle get descriptionStyle => GoogleFonts.vazirmatn(
        fontSize: 12,
        height: 1.8,
        color: secondaryColor,
      );

  // انتقال به صفحه وارد کردن سوالات
  void openImportScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ImportQuestionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,

        // نوار بالای صفحه
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: primaryColor,
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
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معرفی
                      _buildIntroduction(),

                      const SizedBox(height: 28),

                      // انواع سوالات
                      _sectionTitle(
                        'انواع سوالات پشتیبانی‌شده',
                        Icons.quiz_rounded,
                      ),

                      const SizedBox(height: 14),

                      _typeCard(
                        title: 'چندگزینه‌ای',
                        type: 'choice',
                        description:
                            'دارای حداقل دو گزینه است. پاسخ درست را با شماره، حرف گزینه یا متن کامل آن مشخص کنید.',
                        icon: Icons.radio_button_checked_rounded,
                        color: primaryColor,
                      ),

                      _typeCard(
                        title: 'عددی',
                        type: 'number',
                        description:
                            'برای سوالاتی که پاسخ آن‌ها به شکل عدد است.',
                        icon: Icons.numbers_rounded,
                        color: const Color(0xFF6655D9),
                      ),

                      _typeCard(
                        title: 'تشریحی',
                        type: 'text',
                        description:
                            'برای سوالاتی که پاسخ آن‌ها به شکل متن نوشته می‌شود.',
                        icon: Icons.edit_note_rounded,
                        color: const Color(0xFFE67E22),
                      ),

                      _typeCard(
                        title: 'پروژه',
                        type: 'project',
                        description:
                            'برای سوالات پروژه‌ای؛ در صورت نداشتن گزینه، بلی و خیر به‌صورت پیش‌فرض استفاده می‌شوند.',
                        icon: Icons.assignment_rounded,
                        color: greenColor,
                      ),

                      const SizedBox(height: 28),

                      // نکات مهم
                      _sectionTitle(
                        'نکات مهم',
                        Icons.checklist_rounded,
                      ),

                      const SizedBox(height: 14),

                      _noteItem(
                        'فایل باید با فرمت .xlsx باشد.',
                      ),

                      _noteItem(
                        'ستون Question یا سوال برای تمام سوالات ضروری است.',
                      ),

                      _noteItem(
                        'هر سوال را در یک ردیف جداگانه بنویسید.',
                      ),

                      _noteItem(
                        'نوع سوال می‌تواند choice، number، text یا project باشد.',
                      ),

                      _noteItem(
                        'برای سوال چندگزینه‌ای حداقل دو گزینه لازم است؛ نوع آن به‌صورت خودکار تشخیص داده می‌شود.',
                      ),

                      _noteItem(
                        'برای سوالات عددی، تشریحی و پروژه باید ستون Type مشخص باشد.',
                      ),

                      _noteItem(
                        'پاسخ درست اختیاری است و می‌تواند با شماره گزینه، حرف گزینه یا متن کامل آن مشخص شود.',
                      ),

                      const SizedBox(height: 12),

                      // هشدار
                      _warningBox(),
                    ],
                  ),
                ),
              ),

              // دکمه پایین صفحه
              _buildBottomButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // معرفی صفحه
  Widget _buildIntroduction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1565E8),
            Color(0xFF42A5F5),
          ],
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
            'راهنمای آماده‌سازی سوالات',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            'برای وارد کردن سوالات به EduExam، ابتدا با انواع سوالات و نکات مهم فایل Excel آشنا شوید.',
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

  // عنوان بخش‌ها
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
          child: Icon(
            icon,
            color: primaryColor,
            size: 21,
          ),
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

  // کارت انواع سوالات
  Widget _typeCard({
    required String title,
    required String type,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE8EEF6),
        ),
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
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: headingStyle,
                      ),
                    ),

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

                Text(
                  description,
                  style: descriptionStyle,
                ),
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
          const Icon(
            Icons.check_circle_rounded,
            color: greenColor,
            size: 18,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              text,
              style: descriptionStyle,
            ),
          ),
        ],
      ),
    );
  }

  // هشدار پایانی
  Widget _warningBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFFFE2B8),
        ),
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
              'قبل از وارد کردن فایل، نام ستون‌ها و اطلاعات سوالات را بررسی کنید.',
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

  // دکمه پایین صفحه
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),

              Text(
                'ادامه و انتخاب فایل Excel',
                style: GoogleFonts.vazirmatn(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}