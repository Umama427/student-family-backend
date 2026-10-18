import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/fee_provider.dart';
import '../models/student_model.dart';
import '../utils/app_theme.dart';

class AddChallanDialog extends StatefulWidget {
  const AddChallanDialog({super.key});

  @override
  State<AddChallanDialog> createState() => _AddChallanDialogState();
}

class _AddChallanDialogState extends State<AddChallanDialog> {
  final _formKey = GlobalKey<FormState>();
  StudentModel? _selectedStudent;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 10));
  bool _isSubmitting = false;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  double get _tuitionFee => _selectedStudent?.monthlyTuitionFee ?? 0;
  double get _discountPercentage => _selectedStudent?.discountPercentage ?? 0;
  double get _discountAmount => (_tuitionFee * _discountPercentage) / 100;
  double get _totalPayable => _tuitionFee - _discountAmount;

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student'), backgroundColor: AppColors.overdueCrimson),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'studentId': _selectedStudent!.id,
      'month': _selectedMonth,
      'year': _selectedYear,
      'otherCharges': [],
      'dueDate': _dueDate.toIso8601String(),
    };

    final provider = Provider.of<FeeProvider>(context, listen: false);
    final success = await provider.addChallan(data);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challan created successfully! 🎉'), backgroundColor: AppColors.mintEmerald),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: AppColors.overdueCrimson),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        return Dialog(
          backgroundColor: context.cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxHeight: 650),
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
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Create Fee Challan',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textDarkColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<StudentModel>(
                      value: _selectedStudent,
                      dropdownColor: context.cardWhite,
                      style: TextStyle(color: context.textDarkColor),
                      decoration: InputDecoration(
                        labelText: 'Select Student',
                        labelStyle: TextStyle(color: context.textGreyColor),
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: context.textGreyColor),
                        filled: true,
                        fillColor: context.bgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: studentProvider.students.map((s) {
                        return DropdownMenuItem(value: s, child: Text('${s.fullName} (${s.rollNumber})'));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedStudent = value),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            dropdownColor: context.cardWhite,
                            style: TextStyle(color: context.textDarkColor),
                            decoration: InputDecoration(
                              labelText: 'Month',
                              labelStyle: TextStyle(color: context.textGreyColor),
                              filled: true,
                              fillColor: context.bgLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            items: List.generate(12, (i) => i + 1).map((m) {
                              return DropdownMenuItem(value: m, child: Text(_monthNames[m - 1]));
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedMonth = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _selectedYear.toString(),
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: context.textDarkColor),
                            decoration: InputDecoration(
                              labelText: 'Year',
                              labelStyle: TextStyle(color: context.textGreyColor),
                              filled: true,
                              fillColor: context.bgLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            onChanged: (value) => _selectedYear = int.tryParse(value) ?? _selectedYear,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    InkWell(
                      onTap: _pickDueDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: context.bgLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 18, color: context.textGreyColor),
                            const SizedBox(width: 12),
                            Text(
                              'Due Date: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                              style: TextStyle(color: context.textDarkColor),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== Fee Breakdown Preview =====
                    if (_selectedStudent != null)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.mintEmerald.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.mintEmerald.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calculate_rounded, color: AppColors.mintEmerald, size: 18),
                                SizedBox(width: 8),
                                Text('Fee Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _row(context, 'Tuition Fee', 'Rs. ${_tuitionFee.toStringAsFixed(0)}'),
                            _row(context, 'Discount (${_discountPercentage.toInt()}%)', '- Rs. ${_discountAmount.toStringAsFixed(0)}'),
                            Divider(height: 18, color: context.borderColor),
                            _row(context, 'Total Payable', 'Rs. ${_totalPayable.toStringAsFixed(0)}', isBold: true),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
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
                                : const Text('Create Challan'),
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

  Widget _row(BuildContext context, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isBold ? context.textDarkColor : context.textGreyColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: context.textDarkColor,
            ),
          ),
        ],
      ),
    );
  }
}