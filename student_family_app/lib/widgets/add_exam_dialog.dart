import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class AddExamDialog extends StatefulWidget {
  const AddExamDialog({super.key});

  @override
  State<AddExamDialog> createState() => _AddExamDialogState();
}

class _AddExamDialogState extends State<AddExamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  String _examType = 'Midterm';
  DateTime _examDate = DateTime.now();
  bool _isSubmitting = false;

  // ✅ FIX: Class ab dropdown se select hoga (free-text nahi) — taake
  // className hamesha DB mein maujood real class se match kare.
  List<dynamic> _classes = [];
  String? _selectedClassId;
  String? _selectedClassName;
  bool _isLoadingClasses = true;

  // ✅ FIX: Subjects ab 'Subject' collection se load hongi (same jo
  // seedClass.js se seed hui thi / teachers ko assign hoti hain),
  // manually type nahi hongi — taake Bulk Result Entry mein teacher ki
  // assignedSubjects se match ho saken.
  List<dynamic> _availableSubjects = [];
  bool _isLoadingSubjects = false;

  // subjectId -> {selected: bool, totalCtrl, passingCtrl, subjectName}
  final Map<String, Map<String, dynamic>> _subjectSelection = {};

  final List<String> _examTypes = ['Monthly Test', 'Midterm', 'Final Term', 'Quiz', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final classes = await ApiService.getClasses();
      setState(() {
        _classes = classes;
        _isLoadingClasses = false;
      });
    } catch (e) {
      setState(() => _isLoadingClasses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classes: $e')),
        );
      }
    }
  }

  Future<void> _onClassChanged(String? classId) async {
    final cls = _classes.firstWhere((c) => c['_id'] == classId, orElse: () => null);
    if (cls == null) return;

    setState(() {
      _selectedClassId = classId;
      _selectedClassName = cls['className'];
      _availableSubjects = [];
      _subjectSelection.clear();
      _isLoadingSubjects = true;
    });

    try {
      final subjects = await ApiService.getSubjects(classId: classId);
      setState(() {
        _availableSubjects = subjects;
        for (final s in subjects) {
          final id = s['_id'] as String;
          _subjectSelection[id] = {
            'selected': true,
            'subjectName': s['subjectName'],
            'totalCtrl': TextEditingController(
                text: (s['totalMarks'] ?? 100).toString()),
            'passingCtrl': TextEditingController(
                text: (s['passingMarks'] ?? 50).toString()),
          };
        }
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class')),
      );
      return;
    }

    final subjectsData = _subjectSelection.values
        .where((s) => s['selected'] == true)
        .map((s) => {
              'subjectName': s['subjectName'],
              'totalMarks': double.tryParse(s['totalCtrl'].text) ?? 100,
              'passingMarks': double.tryParse(s['passingCtrl'].text) ?? 50,
            })
        .toList();

    if (subjectsData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one subject')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await Provider.of<ExamProvider>(context, listen: false).createExam({
      'examName': _examNameController.text.trim(),
      'examType': _examType,
      'className': _selectedClassName,
      'examDate': _examDate.toIso8601String(),
      'subjects': subjectsData,
    });

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam created successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create exam')),
      );
    }
  }

  @override
  void dispose() {
    _examNameController.dispose();
    for (final s in _subjectSelection.values) {
      s['totalCtrl'].dispose();
      s['passingCtrl'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create New Exam',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textDarkColor),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _examNameController,
                        style: TextStyle(color: context.textDarkColor),
                        decoration: _decoration('Exam Name', context),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _examType,
                        dropdownColor: context.cardWhite,
                        style: TextStyle(color: context.textDarkColor),
                        decoration: _decoration('Exam Type', context),
                        items: _examTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _examType = v!),
                      ),
                      const SizedBox(height: 14),

                      // ✅ FIX: Class ab dropdown se select hoti hai (DB se),
                      // free-text TextFormField hata diya gaya
                      _isLoadingClasses
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedClassId,
                              isExpanded: true,
                              dropdownColor: context.cardWhite,
                              style: TextStyle(color: context.textDarkColor),
                              decoration: _decoration('Class', context),
                              items: _classes
                                  .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                                        value: c['_id'] as String,
                                        child: Text(c['className'] ?? ''),
                                      ))
                                  .toList(),
                              onChanged: _onClassChanged,
                              validator: (v) => v == null ? 'Please select a class' : null,
                            ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: _decoration('Exam Date', context),
                          child: Text(
                            '${_examDate.day}/${_examDate.month}/${_examDate.year}',
                            style: TextStyle(color: context.textDarkColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Subjects',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textDarkColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subjects are loaded from the selected class\'s curriculum.',
                        style: TextStyle(fontSize: 12, color: context.textGreyColor),
                      ),
                      const SizedBox(height: 8),

                      // ✅ FIX: Subjects ab dynamically load hoti hain selected
                      // class ke liye (Subject collection se) — manually type
                      // nahi hotin. Isse teacher ki assignedSubjects se naam
                      // hamesha match honge.
                      if (_selectedClassId == null)
                        Text(
                          'Select a class first to load its subjects.',
                          style: TextStyle(color: context.textGreyColor),
                        )
                      else if (_isLoadingSubjects)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_availableSubjects.isEmpty)
                        const Text(
                          'No subjects found for this class. Please add subjects for this class first.',
                          style: TextStyle(color: AppColors.overdueCrimson),
                        )
                      else
                        ..._availableSubjects.map((s) {
                          final id = s['_id'] as String;
                          final entry = _subjectSelection[id]!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: entry['selected'] as bool,
                                  onChanged: (v) {
                                    setState(() => entry['selected'] = v ?? false);
                                  },
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    entry['subjectName'] ?? '',
                                    style: TextStyle(color: context.textDarkColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: entry['totalCtrl'],
                                    enabled: entry['selected'] as bool,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: context.textDarkColor),
                                    decoration: _decoration('Total', context, dense: true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: entry['passingCtrl'],
                                    enabled: entry['selected'] as bool,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: context.textDarkColor),
                                    decoration: _decoration('Passing', context, dense: true),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create Exam'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, BuildContext context, {bool dense = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.textGreyColor),
      border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.mintEmerald)),
      isDense: dense,
    );
  }
}