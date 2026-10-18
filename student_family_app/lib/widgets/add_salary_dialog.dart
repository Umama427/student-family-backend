import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/staff_provider.dart';
import '../utils/app_theme.dart';

class AddSalaryDialog extends StatefulWidget {
  const AddSalaryDialog({super.key});

  @override
  State<AddSalaryDialog> createState() => _AddSalaryDialogState();
}

class _AddSalaryDialogState extends State<AddSalaryDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStaffId;
  final _monthController = TextEditingController(text: DateTime.now().month.toString());
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  final _bonusController = TextEditingController(text: '0');
  final _deductionsController = TextEditingController(text: '0');
  String _status = 'Paid';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    _bonusController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please select a staff member'), backgroundColor: AppColors.overdueCrimson),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final staffObj = staffProvider.staffList.firstWhere(
        (s) => s['_id'].toString() == _selectedStaffId,
        orElse: () => {},
      );

      final base = (staffObj['baseSalary'] ?? 0).toDouble();

      final salaryData = {
        'staffId': _selectedStaffId,
        'month': _monthController.text.trim(),
        'year': int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
        'baseSalary': base,
        'bonus': double.tryParse(_bonusController.text.trim()) ?? 0.0,
        'deductions': double.tryParse(_deductionsController.text.trim()) ?? 0.0,
        'status': _status,
      };

      await staffProvider.generateSalary(salaryData);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating salary: $e'), backgroundColor: AppColors.overdueCrimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final staffList = staffProvider.staffList;

    if (_selectedStaffId == null && staffList.isNotEmpty) {
      _selectedStaffId = staffList.first['_id'].toString();
    }

    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generate Salary Slip',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textDarkColor),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.textGreyColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (staffList.isEmpty)
                  Text('No staff members available. Please add staff first.',
                      style: TextStyle(color: AppColors.overdueCrimson))
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStaffId,
                    dropdownColor: context.cardWhite,
                    style: TextStyle(color: context.textDarkColor),
                    decoration: InputDecoration(
                      labelText: 'Select Staff Member *',
                      labelStyle: TextStyle(color: context.textGreyColor),
                      border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                      prefixIcon: Icon(Icons.person, color: context.textGreyColor),
                    ),
                    items: staffList.map((s) {
                      final name = s['fullName'] ?? 'Staff';
                      final desig = s['designation'] ?? '';
                      return DropdownMenuItem<String>(
                        value: s['_id'].toString(),
                        child: Text('$name ($desig)'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStaffId = val),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthController,
                        style: TextStyle(color: context.textDarkColor),
                        decoration: InputDecoration(
                          labelText: 'Month (1-12)',
                          labelStyle: TextStyle(color: context.textGreyColor),
                          border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        style: TextStyle(color: context.textDarkColor),
                        decoration: InputDecoration(
                          labelText: 'Year',
                          labelStyle: TextStyle(color: context.textGreyColor),
                          border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bonusController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.textDarkColor),
                        decoration: InputDecoration(
                          labelText: 'Bonus (Rs.)',
                          labelStyle: TextStyle(color: context.textGreyColor),
                          border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _deductionsController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.textDarkColor),
                        decoration: InputDecoration(
                          labelText: 'Deductions (Rs.)',
                          labelStyle: TextStyle(color: context.textGreyColor),
                          border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  dropdownColor: context.cardWhite,
                  style: TextStyle(color: context.textDarkColor),
                  decoration: InputDecoration(
                    labelText: 'Payment Status',
                    labelStyle: TextStyle(color: context.textGreyColor),
                    border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
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
                      onPressed: _isSubmitting || staffList.isEmpty ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Generate Slip', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}