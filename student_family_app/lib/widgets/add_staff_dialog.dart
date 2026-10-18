import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/staff_provider.dart';
import '../utils/app_theme.dart';

class AddStaffDialog extends StatefulWidget {
  const AddStaffDialog({super.key});

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final staffData = {
        'fullName': _nameController.text.trim(),
        'designation': _designationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'baseSalary': double.tryParse(_salaryController.text.trim()) ?? 0.0,
        'status': 'Active',
      };

      await Provider.of<StaffProvider>(context, listen: false).addStaff(staffData);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding staff: $e'), backgroundColor: AppColors.overdueCrimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                    'Add New Staff Member',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textDarkColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textGreyColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.textDarkColor),
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  labelStyle: TextStyle(color: context.textGreyColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  prefixIcon: Icon(Icons.person_outline, color: context.textGreyColor),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _designationController,
                style: TextStyle(color: context.textDarkColor),
                decoration: InputDecoration(
                  labelText: 'Designation (e.g. Teacher, Admin) *',
                  labelStyle: TextStyle(color: context.textGreyColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  prefixIcon: Icon(Icons.work_outline, color: context.textGreyColor),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter designation' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: context.textDarkColor),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: context.textGreyColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  prefixIcon: Icon(Icons.phone_outlined, color: context.textGreyColor),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: context.textDarkColor),
                decoration: InputDecoration(
                  labelText: 'Base Salary (Rs.) *',
                  labelStyle: TextStyle(color: context.textGreyColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  prefixIcon: Icon(Icons.payments_outlined, color: context.textGreyColor),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter base salary';
                  if (double.tryParse(val) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: context.textDarkColor)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Staff', style: TextStyle(color: Colors.white)),
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