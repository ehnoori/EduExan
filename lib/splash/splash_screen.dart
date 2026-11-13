
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _iconScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0,
        0.7,
        curve: Curves.elasticOut,
      ),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.25,
        1,
        curve: Curves.easeIn,
      ),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.25,
          1,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // انتقال به صفحه اصلی
  void _start() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, animation, __) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // استایل نوشته‌ها
  TextStyle _style(
    double size,
    Color color,
    FontWeight weight,
  ) {
    return GoogleFonts.notoSansArabic(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.7,
    );
  }

  @override
  Widget build(BuildContext context) {

    const blue = Color(0xFF3478F6);
    const navy = Color(0xFF172B5B);
    const lightBlue = Color(0xFF42A5F5);
    const background = Color(0xFFF5F8FF);

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Stack(
          children: [

            // دایره تزئینی بالا
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blue.withValues(alpha: 0.055),
                ),
              ),
            ),

            // دایره تزئینی پایین
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF16B89A)
                      .withValues(alpha: 0.055),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),

              child: Column(
                children: [

                  const Spacer(flex: 2),

                  // لوگوی EduExam بدون کادر سفید
                  ScaleTransition(
                    scale: _iconScale,

                    child: Image.asset(
                      'assets/images/a_clean_modern_high_resolution_vector_3d_style_e.png',
                      width: 350,
                      height: 350,
                      fit: BoxFit.contain,
                    ),
                  ),

                 // const SizedBox(height: 10),

                  // عنوان و توضیحات
                  FadeTransition(
                    opacity: _fade,

                    child: SlideTransition(
                      position: _slide,

                      child: Column(
                        children: [

                          Text(
                            'به اپلیکیشن ارزیابی صنف',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,

                            style: _style(
                              screenWidth * 0.070,
                              navy,
                              FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'خوش آمدید!',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,

                            style: _style(
                              screenWidth * 0.095,
                              blue,
                              FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // خط تزئینی
                          Container(
                            width: 170,
                            height: 4,

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),

                              gradient: const LinearGradient(
                                colors: [
                                  lightBlue,
                                  blue,
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          Text(
                            'صنف‌ها، اعضا و ارزیابی‌ها را به آسانی '
                            'مدیریت کنید و نتایج را به صورت فایل '
                            'Excel دریافت کنید.',

                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,

                            style: _style(
                              screenWidth * 0.038,
                              const Color(0xFF596B91),
                              FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // دکمه شروع
                  FadeTransition(
                    opacity: _fade,

                    child: SizedBox(
                      width: double.infinity,
                      height: 62,

                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3478F6),
                              Color(0xFF2259D6),
                            ],
                          ),

                          borderRadius: BorderRadius.circular(20),

                          boxShadow: [
                            BoxShadow(
                              color: blue.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: ElevatedButton(
                          onPressed: _start,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              Text(
                                'شروع کنید',
                                textDirection: TextDirection.rtl,

                                style: _style(
                                  17,
                                  Colors.white,
                                  FontWeight.w700,
                                ),
                              ),

                            
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
