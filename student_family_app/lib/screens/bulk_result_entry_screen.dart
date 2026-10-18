import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class BulkResultEntryScreen extends StatefulWidget {
  const BulkResultEntryScreen({super.key});

  @override
  State<BulkResultEntryScreen> createState() => _BulkResultEntryScreenState();
}

class _BulkResultEntryScreenState extends State<BulkResultEntryScreen> {
  bool isLoading = true;
  bool isSubmitting = false;
  String? message;
  bool isError = false;

  List exams = [];
  List allStudents = [];
  List studentsForExam = [];

  // ✅ NEW: Role-based access control (teacher = restricted to own classes/subjects)
  String? _role;
  List<String> _assignedClasses = [];
  List<String> _assignedSubjects = [];

  // ✅ FIX: Track exam by stable ID (String) instead of Map object
  String? selectedExamId;
  String? selectedSubject;

  final Map<String, TextEditingController> markControllers = {};

  // ✅ FIX: Resolve the actual exam Map from the list using the ID (safe, no identity issues)
  Map<String, dynamic>? get selectedExam {
    if (selectedExamId == null) return null;
    for (final e in exams) {
      if (e['_id'] == selectedExamId) {
        return Map<String, dynamic>.from(e);
      }
    }
    return null;
  }

  // ✅ NEW: Exams visible to current user.
  // Admin => all exams. Teacher => only exams for their assigned classes.
  List get visibleExams {
    if (_role != 'teacher') return exams;
    return exams.where((e) => _assignedClasses.contains(e['className'])).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final role = await AuthService.getRole();
      final assignedClasses =
          role == 'teacher' ? await AuthService.getAssignedClasses() : <String>[];
      final assignedSubjects =
          role == 'teacher' ? await AuthService.getAssignedSubjects() : <String>[];

      final examsData = await ApiService.getExams();
      final studentsData = await ApiService.getStudents();

      setState(() {
        _role = role;
        _assignedClasses = assignedClasses;
        _assignedSubjects = assignedSubjects;
        exams = examsData;
        allStudents = studentsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        message = 'Failed to load data: $e';
        isError = true;
        isLoading = false;
      });
    }
  }

  // ✅ FIX: Now receives the exam ID (String) instead of a Map
  void _onExamChanged(String? examId) {
    setState(() {
      selectedExamId = examId;
      selectedSubject = null;
      _loadStudentsForExam();
    });
  }

  void _loadStudentsForExam() {
    markControllers.clear();
    if (selectedExam == null) {
      studentsForExam = [];
      return;
    }
    final className = selectedExam!['className'];
    studentsForExam =
        allStudents.where((s) => s['className'] == className).toList();
    studentsForExam.sort((a, b) =>
        (a['rollNumber'] ?? '').toString().compareTo((b['rollNumber'] ?? '').toString()));

    for (final s in studentsForExam) {
      markControllers[s['_id']] = TextEditingController();
    }
  }

  // ✅ FIX: Subjects visible to current user.
  // Admin => all subjects of the exam. Teacher => only their assignedSubjects
  // (so a teacher can't enter marks for a subject they don't teach).
  List get subjectsForExam {
    if (selectedExam == null) return [];
    final allSubjects = (selectedExam!['subjects'] as List?) ?? [];
    if (_role != 'teacher') return allSubjects;
    return allSubjects
        .where((s) => _assignedSubjects.contains(s['subjectName']))
        .toList();
  }

  Future<void> _submit() async {
    if (selectedExam == null || selectedSubject == null) {
      setState(() {
        message = 'Please select exam and subject.';
        isError = true;
      });
      return;
    }

    final marks = <Map<String, dynamic>>[];
    markControllers.forEach((studentId, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) {
          marks.add({'studentId': studentId, 'marksObtained': value});
        }
      }
    });

    if (marks.isEmpty) {
      setState(() {
        message = 'Please enter marks for at least one student.';
        isError = true;
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      message = null;
    });

    try {
      await ApiService.bulkEnterResults({
        'examId': selectedExam!['_id'],
        'subjectName': selectedSubject,
        'marks': marks,
      });

      setState(() {
        isError = false;
        message = 'Marks saved successfully for ${marks.length} student(s).';
        isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        isError = true;
        message = 'Failed to save marks: $e';
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in markControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.mintEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Bulk Result Entry'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.cardWhite,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: context.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Exam', style: AppText.bodyBold.copyWith(color: context.textDarkColor)),
                              const SizedBox(height: 8),
                              // ✅ FIX: DropdownButtonFormField<String>, filtered by role
                              DropdownButtonFormField<String>(
                                value: selectedExamId,
                                isExpanded: true,
                                dropdownColor: context.cardWhite,
                                style: TextStyle(color: context.textDarkColor),
                                decoration: _inputDecoration('Select exam', context),
                                items: visibleExams
                                    .map<DropdownMenuItem<String>>((e) =>
                                        DropdownMenuItem<String>(
                                          value: e['_id'] as String,
                                          child: Text(
                                              '${e['examName']} (${e['className']})'),
                                        ))
                                    .toList(),
                                onChanged: _onExamChanged,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Subject', style: AppText.bodyBold.copyWith(color: context.textDarkColor)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedSubject,
                                isExpanded: true,
                                dropdownColor: context.cardWhite,
                                style: TextStyle(color: context.textDarkColor),
                                decoration: _inputDecoration('Select subject', context),
                                items: subjectsForExam
                                    .map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                                          value: s['subjectName'],
                                          child: Text(
                                              '${s['subjectName']} (Max: ${s['totalMarks']})'),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => selectedSubject = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (message != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: (isError ? AppColors.overdueCrimson : AppColors.paidGreen)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        message!,
                        style: TextStyle(
                          color: isError ? AppColors.overdueCrimson : AppColors.paidGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  Expanded(
                    child: selectedExam == null
                        ? Center(
                            child: Text(
                              'Select an exam to load students.',
                              style: TextStyle(color: context.textGreyColor),
                            ),
                          )
                        : studentsForExam.isEmpty
                            ? Center(
                                child: Text(
                                  'No students found for this class.',
                                  style: TextStyle(color: context.textGreyColor),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: context.cardWhite,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  boxShadow: context.cardShadow,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.mintEmerald.withValues(alpha: 0.08),
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(16)),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                              width: 100,
                                              child: Text('Roll No',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textDarkColor))),
                                          Expanded(
                                              child: Text('Name',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textDarkColor))),
                                          SizedBox(
                                              width: 140,
                                              child: Text('Marks Obtained',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textDarkColor))),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: studentsForExam.length,
                                        separatorBuilder: (_, __) =>
                                            Divider(height: 1, color: context.borderColor),
                                        itemBuilder: (context, index) {
                                          final s = studentsForExam[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      s['rollNumber'] ?? '',
                                                      style: TextStyle(color: context.textDarkColor),
                                                    )),
                                                Expanded(
                                                    child: Text(
                                                  s['fullName'] ?? '',
                                                  style: TextStyle(color: context.textDarkColor),
                                                )),
                                                SizedBox(
                                                  width: 140,
                                                  child: TextField(
                                                    controller: markControllers[s['_id']],
                                                    keyboardType: TextInputType.number,
                                                    style: TextStyle(color: context.textDarkColor),
                                                    decoration: _inputDecoration('Marks', context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save All Marks'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint, BuildContext context) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMutedColor),
      filled: true,
      fillColor: context.bgLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.borderColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      isDense: true,
    );
  }
}