
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color primaryColor = Color(0xFF1565E8);
  static const Color backgroundColor = Color(0xFFF3F7FC);
  static const Color textColor = Color(0xFF172B5B);
  static const Color secondaryColor = Color(0xFF68758A);

  final PageController _pageController = PageController();

  int currentPage = 0;
  bool isChecking = true;
  bool isFinishing = false;

  final List<Map<String, dynamic>> pages = [
    {
      'title': 'به EduExam خوش آمدید',
      'description':
          'با EduExam فعالیت‌های آموزشی خود را آسان‌تر مدیریت کنید و تمام امکانات مورد نیاز را در یک برنامه داشته باشید.',
      'subtitle': 'مدیریت آسان و هوشمند آموزشی',
      'icon': Icons.school_rounded,
      'color': Color(0xFF1565E8),
      'smallIcon': Icons.auto_awesome_rounded,
    },
    {
      'title': 'مدیریت صنف‌ها',
      'description':
          'صنف‌های جدید ایجاد کنید، معلومات آن‌ها را ثبت نمایید و شاگردان خود را به شکل منظم مدیریت کنید.',
      'subtitle': 'تمام صنف‌ها در یک مکان',
      'icon': Icons.groups_rounded,
      'color': Color(0xFF6655D9),
      'smallIcon': Icons.people_alt_rounded,
    },
    {
      'title': 'ارزیابی شاگردان',
      'description':
          'سوالات را وارد کنید، شاگردان را ارزیابی نمایید و نتایج را مشاهده کرده و به فایل Excel صادر کنید.',
      'subtitle': 'ارزیابی دقیق و خروجی Excel',
      'icon': Icons.assignment_rounded,
      'color': Color(0xFF2E9B57),
      'smallIcon': Icons.table_chart_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    checkOnboarding();
  }

  // بررسی وضعیت معرفی برنامه
  Future<void> checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    final completed =
        prefs.getBool('onboarding_completed') ?? false;

    if (!mounted) return;

    if (completed) {
      goToHome();
    } else {
      setState(() {
        isChecking = false;
      });
    }
  }

  // ورود به صفحه اصلی
  void goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  // پایان معرفی
  Future<void> finishOnboarding() async {
    if (isFinishing) return;

    setState(() {
      isFinishing = true;
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    goToHome();
  }

  // رفتن به صفحه بعدی
  void nextPage() {
    if (currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // AppBar
              _buildHeader(),

              // صفحات معرفی
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(pages[index]);
                  },
                ),
              ),

              // قسمت پایین صفحه
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  // AppBar - نام برنامه در وسط
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 18,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_rounded,
              color: primaryColor,
              size: 27,
            ),
            const SizedBox(width: 9),
            Text(
              'EduExam',
              style: GoogleFonts.vazirmatn(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // طراحی صفحات معرفی
  Widget _buildPage(Map<String, dynamic> page) {
    final Color pageColor = page['color'] as Color;
    final double width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 22),

          // تصویر و آیکون اصلی
          Container(
            width: width * 0.72,
            height: width * 0.72,
            constraints: const BoxConstraints(
              maxWidth: 280,
              maxHeight: 280,
            ),
            decoration: BoxDecoration(
              color: pageColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(38),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        pageColor,
                        pageColor.withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: [
                      BoxShadow(
                        color: pageColor.withValues(alpha: 0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    page['icon'] as IconData,
                    color: Colors.white,
                    size: 88,
                  ),
                ),

                // آیکون کوچک بالا
                Positioned(
                  top: 24,
                  right: 24,
                  child: _smallIcon(
                    page['smallIcon'] as IconData,
                    pageColor,
                  ),
                ),

                // آیکون کوچک پایین
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: _smallIcon(
                    Icons.check_rounded,
                    pageColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 35),

          // عنوان صفحه
          Text(
            page['title'] as String,
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 14),

          // توضیحات
          Text(
            page['description'] as String,
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 14,
              height: 2,
              color: secondaryColor,
            ),
          ),

          const SizedBox(height: 25),

          // متن فرعی
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: pageColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 19,
                  color: pageColor,
                ),
                const SizedBox(width: 8),
                Text(
                  page['subtitle'] as String,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pageColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

  // آیکون‌های کوچک
  Widget _smallIcon(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 26,
      ),
    );
  }

  // دکمه‌های پایین صفحه
  Widget _buildBottomNavigation() {
    final bool isLastPage =
        currentPage == pages.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
    // const SizedBox(height: 18),

          // دکمه چپ، نقاط وسط و دکمه راست
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // رد کردن - سمت چپ
                TextButton(
                  onPressed:
                      isFinishing ? null : finishOnboarding,
                  child: Text(
                    'رد کردن',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                    ),
                  ),
                ),

                // سه نقطه وسط
                Row(
                  children: List.generate(
                    pages.length,
                    (index) {
                      final bool selected =
                          currentPage == index;

                      return AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
                        width: selected ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selected
                              ? primaryColor
                              : Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      );
                    },
                  ),
                ),

                // دکمه بعدی - سمت راست
                ElevatedButton(
                  onPressed:
                      isFinishing ? null : nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLastPage ? 'شروع کنید' : 'بعدی',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isLastPage
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
