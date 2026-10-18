import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam_model.dart';
import '../providers/result_provider.dart';
import '../utils/app_theme.dart';

class EnterMarksDialog extends StatefulWidget {
  final ExamModel exam;
  final String studentId;
  final String studentName;

  const EnterMarksDialog({
    super.key,
    required this.exam,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<EnterMarksDialog> createState() => _EnterMarksDialogState();
}

class _EnterMarksDialogState extends State<EnterMarksDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _marksControllers;
  final _remarksController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _marksControllers = {
      for (var s in widget.exam.subjects) s.subjectName: TextEditingController()
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final subjectsData = widget.exam.subjects.map((s) {
      return {
        'subjectName': s.subjectName,
        'marksObtained': double.tryParse(_marksControllers[s.subjectName]!.text) ?? 0,
        'totalMarks': s.totalMarks,
      };
    }).toList();

    setState(() => _isSubmitting = true);

    final success = await Provider.of<ResultProvider>(context, listen: false).createResult({
      'examId': widget.exam.id,
      'studentId': widget.studentId,
      'subjects': subjectsData,
      'remarks': _remarksController.text.trim(),
    }, widget.exam.id);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks saved successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save marks (result may already exist)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter Marks — ${widget.studentName}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textDarkColor)),
              Text(widget.exam.examName, style: TextStyle(color: context.textGreyColor, fontSize: 13)),
              const SizedBox(height: 20),
              ...widget.exam.subjects.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _marksControllers[s.subjectName],
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.textDarkColor),
                      decoration: InputDecoration(
                        labelText: '${s.subjectName} (out of ${s.totalMarks.toInt()})',
                        labelStyle: TextStyle(color: context.textGreyColor),
                        border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final marks = double.tryParse(v);
                        if (marks == null) return 'Invalid number';
                        if (marks > s.totalMarks) return 'Cannot exceed ${s.totalMarks.toInt()}';
                        if (marks < 0) return 'Cannot be negative';
                        return null;
                      },
                    ),
                  )),
              TextFormField(
                controller: _remarksController,
                style: TextStyle(color: context.textDarkColor),
                decoration: InputDecoration(
                  labelText: 'Remarks (optional)',
                  labelStyle: TextStyle(color: context.textGreyColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: context.textDarkColor))),
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
                        : const Text('Save Marks'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}