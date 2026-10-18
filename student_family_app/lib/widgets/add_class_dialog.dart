import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../providers/staff_provider.dart';
import '../utils/app_theme.dart';

class AddClassDialog extends StatefulWidget {
  const AddClassDialog({super.key});

  @override
  State<AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<AddClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _classNameCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController(text: 'A');
  String? _selectedTeacherId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _classNameCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = {
      'className': _classNameCtrl.text.trim(),
      'section': _sectionCtrl.text.trim(),
      if (_selectedTeacherId != null) 'classTeacher': _selectedTeacherId,
    };

    final provider = Provider.of<ClassProvider>(context, listen: false);
    final success = await provider.addClass(data);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created successfully! 🎉'), backgroundColor: AppColors.mintEmerald),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: AppColors.overdueCrimson),
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
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Class',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textDarkColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textGreyColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _classNameCtrl,
                style: TextStyle(color: context.textDarkColor),
                decoration: InputDecoration(
                  labelText: 'Class Name (e.g. Grade 5, BSCS-1st) *',
                  labelStyle: TextStyle(color: context.textGreyColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  prefixIcon: Icon(Icons.class_outlined, color: context.textGreyColor),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter class name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sectionCtrl,
                style: TextStyle(color: context.textDarkColor),
                decoration: InputDecoration(
                  labelText: 'Section',
                  labelStyle: TextStyle(color: context.textGreyColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  prefixIcon: Icon(Icons.grid_view_rounded, color: context.textGreyColor),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedTeacherId,
                dropdownColor: context.cardWhite,
                style: TextStyle(color: context.textDarkColor),
                decoration: InputDecoration(
                  labelText: 'Class Teacher (Optional)',
                  labelStyle: TextStyle(color: context.textGreyColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  prefixIcon: Icon(Icons.person_outline, color: context.textGreyColor),
                ),
                items: staffProvider.staffList.map<DropdownMenuItem<String>>((staff) {
                  final s = Map<String, dynamic>.from(staff);
                  return DropdownMenuItem(
                    value: s['_id'].toString(),
                    child: Text(s['fullName']?.toString() ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTeacherId = val),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Class', style: TextStyle(color: Colors.white)),
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