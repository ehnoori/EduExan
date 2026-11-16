
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/isar_service.dart';
import '../models/class_model.dart';
import 'student_selection_screen.dart';

class ClassManagementScreen extends StatefulWidget {
  final ClassModel? classModel;

  const ClassManagementScreen({
    super.key,
    this.classModel,
  });

  @override
  State<ClassManagementScreen> createState() =>
      _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  // Controllers
  final TextEditingController classNameController =
      TextEditingController();

  final TextEditingController teacherController =
      TextEditingController();

  final TextEditingController startTimeController =
      TextEditingController();

  final TextEditingController endTimeController =
      TextEditingController();

  final TextEditingController memberController =
      TextEditingController();

  final List<TextInputFormatter> timeFormatter = [
    TimeInputFormatter(),
  ];

  // Members
  final List<String> members = [];

  bool isSaving = false;

  // Load existing class information for editing
  @override
  void initState() {
    super.initState();

    final existingClass = widget.classModel;

    if (existingClass != null) {
      classNameController.text = existingClass.className;
      teacherController.text = existingClass.teacherName;

      final timeParts = existingClass.classTime.split(' - ');

      if (timeParts.length == 2) {
        startTimeController.text = timeParts[0].trim();
        endTimeController.text = timeParts[1].trim();
      }

      members.addAll(existingClass.members);
    }
  }

  @override
  void dispose() {
    classNameController.dispose();
    teacherController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    memberController.dispose();
    super.dispose();
  }

  // Normalize names
  String _normalizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  // Add member
  void addMember() {
    final String memberName = memberController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (memberName.isEmpty) {
      _showMessage('لطفاً نام عضو را وارد کنید');
      return;
    }

    final normalizedName = _normalizeName(memberName);

    final alreadyExists = members.any(
      (member) => _normalizeName(member) == normalizedName,
    );

    if (alreadyExists) {
      _showMessage('این شاگرد قبلاً به صنف اضافه شده است');
      return;
    }

    setState(() {
      members.add(memberName);
      memberController.clear();
    });
  }

  // Remove member
  void removeMember(int index) {
    setState(() {
      members.removeAt(index);
    });
  }

  // Convert time to minutes
  int? _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return null;

    final cleanStr = timeStr.replaceAll('.', ':');
    final parts = cleanStr.split(':');

    if (parts.length == 1) {
      final hour = int.tryParse(parts[0]);

      if (hour == null) return null;

      return hour * 60;
    } else if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) return null;

      if (minute < 0 || minute > 59) return null;

      return (hour * 60) + minute;
    }

    return null;
  }

  // Save class
  Future<void> saveClass() async {
    if (isSaving) return;

    final String className = classNameController.text.trim();
    final String teacherName = teacherController.text.trim();
    final String startTime = startTimeController.text.trim();
    final String endTime = endTimeController.text.trim();

    // Required: Class name
    if (className.isEmpty) {
      _showMessage('لطفاً نام صنف را وارد کنید');
      return;
    }

    // Required: Teacher name
    if (teacherName.isEmpty) {
      _showMessage('لطفاً نام استاد را وارد کنید');
      return;
    }

    // Optional: Time fields
    int? startMinutes;
    int? endMinutes;

    if (startTime.isNotEmpty) {
      startMinutes = _parseTimeToMinutes(startTime);

      if (startMinutes == null ||
          startMinutes < 0 ||
          startMinutes > 23 * 60 + 59) {
        _showMessage('فرمت ساعت شروع اشتباه است');
        return;
      }
    }

    if (endTime.isNotEmpty) {
      endMinutes = _parseTimeToMinutes(endTime);

      if (endMinutes == null ||
          endMinutes <= 0 ||
          endMinutes > 24 * 60) {
        _showMessage('فرمت ساعت ختم اشتباه است');
        return;
      }
    }

    // // Compare only when both times are entered
    // if (startMinutes != null &&
    //     endMinutes != null &&
    //     startMinutes >= endMinutes) {
    //   _showMessage('زمان شروع باید قبل از زمان ختم باشد');
    //   return;
    // }

    // Optional time
    final String classTime =
        startTime.isEmpty && endTime.isEmpty
            ? ''
            : '$startTime - $endTime';

    // Members are optional
    final normalizedMembers = members.map(_normalizeName).toList();

    if (normalizedMembers.toSet().length != normalizedMembers.length) {
      _showMessage('نام تکراری در فهرست شاگردان وجود دارد');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Update existing class or create new class
      final ClassModel classToSave =
          widget.classModel ?? ClassModel();

      classToSave
        ..className = className
        ..teacherName = teacherName
        ..classTime = classTime
        ..members = List<String>.from(members);

      final isar = await IsarService.getInstance();

      await isar.writeTxn(() async {
        await isar.classModels.put(classToSave);
      });

      final savedClass =
          await isar.classModels.get(classToSave.id);

      if (savedClass == null) {
        throw Exception('صنف در دیتابیس ذخیره نشد');
      }

      if (!mounted) return;

      // Editing mode
      if (widget.classModel != null) {
        Navigator.pop(context, true);
        return;
      }

      // Creating mode
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentSelectionScreen(
            classModel: savedClass,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Save Class Error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      _showMessage('خطا در ذخیره صنف');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // Show message
  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.vazirmatn(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: success
              ? const Color(0xFF27AE60)
              : const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // Label
  Widget _label(String text, {bool required = false}) {
    return Align(
      alignment: Alignment.centerRight,
      child: RichText(
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF263238),
              ),
            ),
            if (required)
              TextSpan(
                text: ' *',
                style: GoogleFonts.vazirmatn(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Text field
  Widget _textField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: GoogleFonts.vazirmatn(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF263238),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintTextDirection: TextDirection.rtl,
        hintStyle: GoogleFonts.vazirmatn(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF9AA7B2),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF6C63FF),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE1E8EF),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE1E8EF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF6C63FF),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // Start and end time fields
  Widget _timeFields() {
    return Row(
      children: [
        Expanded(
          child: _textField(
            controller: startTimeController,
            hintText: 'شروع',
            icon: Icons.access_time_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: timeFormatter,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _textField(
            controller: endTimeController,
            hintText: 'ختم',
            icon: Icons.access_time_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: timeFormatter,
          ),
        ),
      ],
    );
  }

  // Add member input
  Widget _memberInput() {
    return Row(
      children: [
        Container(
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: addMember,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _textField(
            controller: memberController,
            hintText: 'نام عضو را وارد کنید',
            icon: Icons.person_add_alt_1_rounded,
          ),
        ),
      ],
    );
  }

  // Members list
  Widget _buildMembersList() {
    if (members.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5EAF0),
          ),
        ),
        child: Text(
          'هنوز عضوی اضافه نشده است',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: GoogleFonts.vazirmatn(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF9AA7B2),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(members.length, (index) {
        final String member = members[index];

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5EAF0),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF6C63FF),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  member,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF263238),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'حذف عضو',
                onPressed: () => removeMember(index),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE74C3C),
                  size: 23,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7FC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF3F7FC),
          centerTitle: true,
          title: Text(
            'مشخصات صنف',
            style: GoogleFonts.vazirmatn(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF263238),
            ),
          ),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF263238),
              size: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('نام صنف :', required: true),
                const SizedBox(height: 8),
                _textField(
                  controller: classNameController,
                  hintText: 'مثال: علوم کامپیوتر',
                  icon: Icons.class_rounded,
                ),
                const SizedBox(height: 17),

                _label('نام استاد :', required: true),
                const SizedBox(height: 8),
                _textField(
                  controller: teacherController,
                  hintText: 'نام استاد را وارد کنید',
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 17),

                _label('تایم درسی :'),
                const SizedBox(height: 8),
                _timeFields(),
                const SizedBox(height: 22),

                _label('اعضای صنف :'),
                const SizedBox(height: 8),
                _memberInput(),
                const SizedBox(height: 12),
                _buildMembersList(),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveClass,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      disabledBackgroundColor: const Color(0xFF9E98F5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.ltr,
                      children: [
                        
                     
                        const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                           const SizedBox(width: 20),
                        Text(
                          isSaving ? 'در حال ذخیره...' : 'ذخیره صنف',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Automatically format time: 1220 -> 12:20
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }

    String formatted = digits;

    if (digits.length > 2) {
      formatted =
          '${digits.substring(0, 2)}:${digits.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}
