import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';
import '../providers/student_provider.dart';
import '../models/family_model.dart';
import '../utils/app_theme.dart';

class AddStudentDialog extends StatefulWidget {
  const AddStudentDialog({super.key});

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _tuitionCtrl = TextEditingController(text: '5000');
  final _contactCtrl = TextEditingController();

  FamilyModel? _selectedFamily;
  String _gender = 'male';
  bool _isSubmitting = false;

  int get _siblingOrder {
    if (_selectedFamily == null) return 1;
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final existingCount = studentProvider.getStudentsByFamily(_selectedFamily!.id).length;
    return existingCount + 1;
  }

  double get _discountPercentage {
    final order = _siblingOrder;
    if (order == 1) return 0;
    if (order == 2) return 15;
    return 25;
  }

  double get _tuitionFee => double.tryParse(_tuitionCtrl.text) ?? 0;
  double get _discountAmount => (_tuitionFee * _discountPercentage) / 100;
  double get _finalFee => _tuitionFee - _discountAmount;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _tuitionCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a family'), backgroundColor: AppColors.overdueCrimson),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'familyId': _selectedFamily!.id,
      'fullName': _nameCtrl.text.trim(),
      'className': _classCtrl.text.trim(),
      'gender': _gender,
      'siblingOrder': _siblingOrder,
      'discountPercentage': _discountPercentage,
      'monthlyTuitionFee': _tuitionFee,
      'status': 'active',
      'contactNumber': _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
    };

    final provider = Provider.of<StudentProvider>(context, listen: false);
    final success = await provider.addStudent(data);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully! 🎉'), backgroundColor: AppColors.mintEmerald),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: AppColors.overdueCrimson),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyProvider>(
      builder: (context, familyProvider, child) {
        return Dialog(
          backgroundColor: context.cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.navyGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Text('Add New Student',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textDarkColor)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<FamilyModel>(
                      initialValue: _selectedFamily,
                      dropdownColor: context.cardWhite,
                      style: TextStyle(color: context.textDarkColor),
                      decoration: InputDecoration(
                        labelText: 'Select Family',
                        labelStyle: TextStyle(color: context.textGreyColor),
                        prefixIcon: Icon(Icons.family_restroom_rounded, size: 20, color: context.textGreyColor),
                        filled: true,
                        fillColor: context.bgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: familyProvider.families.map((f) {
                        return DropdownMenuItem(value: f, child: Text('${f.familyName} (${f.familyCode})'));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedFamily = value),
                      validator: (value) => value == null ? 'Please select a family' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildField(context, _nameCtrl, 'Student Full Name', Icons.person_outline_rounded, required: true),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildField(context, _classCtrl, 'Class (e.g. 5th)', Icons.class_outlined, required: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            dropdownColor: context.cardWhite,
                            style: TextStyle(color: context.textDarkColor),
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              labelStyle: TextStyle(color: context.textGreyColor),
                              filled: true,
                              fillColor: context.bgLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                            ],
                            onChanged: (value) => setState(() => _gender = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildField(context, _tuitionCtrl, 'Monthly Tuition Fee (Rs.)', Icons.attach_money_rounded,
                        required: true, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                    const SizedBox(height: 14),

                    _buildField(context, _contactCtrl, 'Contact Number (Optional)', Icons.phone_outlined,
                        required: false, keyboardType: TextInputType.phone),

                    const SizedBox(height: 20),

                    if (_selectedFamily != null) _buildFeeSimulator(context),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: context.borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel', style: TextStyle(color: context.textDarkColor)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save Student'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeeSimulator(BuildContext context) {
    final color = _discountPercentage == 0
        ? AppColors.deepNavy
        : (_discountPercentage < 20 ? AppColors.accentGold : AppColors.coral);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                'Live Fee Simulator — Sibling #$_siblingOrder',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _simRow(context, 'Tuition Fee', 'Rs. ${_tuitionFee.toStringAsFixed(0)}'),
          _simRow(context, 'Sibling Discount', '${_discountPercentage.toInt()}% (- Rs. ${_discountAmount.toStringAsFixed(0)})'),
          Divider(height: 20, color: context.borderColor),
          _simRow(context, 'Final Monthly Fee', 'Rs. ${_finalFee.toStringAsFixed(0)}', isBold: true, color: color),
        ],
      ),
    );
  }

  Widget _simRow(BuildContext context, String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isBold ? color : context.textGreyColor)),
          Text(value,
              style: TextStyle(
                  fontSize: isBold ? 15 : 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: isBold ? color : context.textDarkColor)),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, TextEditingController ctrl, String label, IconData icon,
      {bool required = false, TextInputType keyboardType = TextInputType.text, Function(String)? onChanged}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(color: context.textDarkColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.textGreyColor),
        prefixIcon: Icon(icon, size: 20, color: context.textGreyColor),
        filled: true,
        fillColor: context.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: required ? (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null : null,
    );
  }
}