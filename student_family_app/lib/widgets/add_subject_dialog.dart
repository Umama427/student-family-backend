import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../providers/staff_provider.dart';
import '../utils/app_theme.dart';

class AddSubjectDialog extends StatefulWidget {
  final String classId;
  final String className;

  const AddSubjectDialog({super.key, required this.classId, required this.className});

  @override
  State<AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameCtrl = TextEditingController();
  final _subjectCodeCtrl = TextEditingController();
  final _totalMarksCtrl = TextEditingController(text: '100');
  final _passingMarksCtrl = TextEditingController(text: '40');
  String? _selectedTeacherId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClassProvider>(context, listen: false).fetchSubjects(widget.classId);
    });
  }

  @override
  void dispose() {
    _subjectNameCtrl.dispose();
    _subjectCodeCtrl.dispose();
    _totalMarksCtrl.dispose();
    _passingMarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = {
      'subjectName': _subjectNameCtrl.text.trim(),
      'subjectCode': _subjectCodeCtrl.text.trim(),
      'classId': widget.classId,
      if (_selectedTeacherId != null) 'teacherId': _selectedTeacherId,
      'totalMarks': int.tryParse(_totalMarksCtrl.text.trim()) ?? 100,
      'passingMarks': int.tryParse(_passingMarksCtrl.text.trim()) ?? 40,
    };

    final provider = Provider.of<ClassProvider>(context, listen: false);
    final success = await provider.addSubject(data);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      _subjectNameCtrl.clear();
      _subjectCodeCtrl.clear();
      await provider.fetchSubjects(widget.classId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject added! 🎉'), backgroundColor: AppColors.mintEmerald),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: AppColors.overdueCrimson),
      );
    }
  }

  Future<void> _deleteSubject(String id) async {
    final provider = Provider.of<ClassProvider>(context, listen: false);
    final success = await provider.removeSubject(id);
    if (success) {
      await provider.fetchSubjects(widget.classId);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Subject deleted' : 'Error: ${provider.errorMessage}'),
          backgroundColor: success ? AppColors.mintEmerald : AppColors.overdueCrimson,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);

    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subjects — ${widget.className}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textDarkColor)),
                IconButton(
                  icon: Icon(Icons.close, color: context.textGreyColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _subjectNameCtrl,
                          style: TextStyle(color: context.textDarkColor),
                          decoration: InputDecoration(
                            labelText: 'Subject Name *',
                            labelStyle: TextStyle(color: context.textGreyColor),
                            border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _subjectCodeCtrl,
                          style: TextStyle(color: context.textDarkColor),
                          decoration: InputDecoration(
                            labelText: 'Code',
                            labelStyle: TextStyle(color: context.textGreyColor),
                            border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _totalMarksCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: context.textDarkColor),
                          decoration: InputDecoration(
                            labelText: 'Total Marks',
                            labelStyle: TextStyle(color: context.textGreyColor),
                            border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _passingMarksCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: context.textDarkColor),
                          decoration: InputDecoration(
                            labelText: 'Passing Marks',
                            labelStyle: TextStyle(color: context.textGreyColor),
                            border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTeacherId,
                    dropdownColor: context.cardWhite,
                    style: TextStyle(color: context.textDarkColor),
                    decoration: InputDecoration(
                      labelText: 'Subject Teacher (Optional)',
                      labelStyle: TextStyle(color: context.textGreyColor),
                      border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                    ),
                    items: staffProvider.staffList.map<DropdownMenuItem<String>>((staff) {
                      final s = Map<String, dynamic>.from(staff);
                      return DropdownMenuItem(
                          value: s['_id'].toString(), child: Text(s['fullName']?.toString() ?? ''));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTeacherId = val),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.add, size: 18),
                      label: const Text('Add Subject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 32, color: context.borderColor),
            Text('Existing Subjects',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textDarkColor)),
            const SizedBox(height: 10),
            Consumer<ClassProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.subjects.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No subjects added yet.', style: TextStyle(color: context.textGreyColor)),
                  );
                }
                return SizedBox(
                  height: 180,
                  child: ListView.separated(
                    itemCount: provider.subjects.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: context.borderColor),
                    itemBuilder: (context, index) {
                      final subj = Map<String, dynamic>.from(provider.subjects[index]);
                      final teacherObj = subj['teacher'];
                      final teacherName = teacherObj is Map ? teacherObj['fullName'] : null;
                      return ListTile(
                        dense: true,
                        title: Text(subj['subjectName']?.toString() ?? '', style: TextStyle(color: context.textDarkColor)),
                        subtitle: Text('Code: ${subj['subjectCode'] ?? '-'} • Teacher: ${teacherName ?? 'Not assigned'}',
                            style: TextStyle(color: context.textGreyColor)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: AppColors.overdueCrimson, size: 20),
                          onPressed: () => _deleteSubject(subj['_id'].toString()),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}