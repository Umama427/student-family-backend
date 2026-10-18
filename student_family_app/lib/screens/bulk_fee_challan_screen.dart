import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class BulkFeeChallanScreen extends StatefulWidget {
  const BulkFeeChallanScreen({super.key});

  @override
  State<BulkFeeChallanScreen> createState() => _BulkFeeChallanScreenState();
}

class _BulkFeeChallanScreenState extends State<BulkFeeChallanScreen> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _classes = [];
  bool _loadingClasses = true;
  bool _submitting = false;

  String? _selectedClassName;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 10));

  final List<_OtherCharge> _otherCharges = [];

  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final response = await ApiService.getClasses();
      if (!mounted) return;
      setState(() {
        _classes = response;
        _loadingClasses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingClasses = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load classes: $e')),
      );
    }
  }

  void _addOtherCharge() {
    setState(() {
      _otherCharges.add(_OtherCharge());
    });
  }

  void _removeOtherCharge(int index) {
    setState(() {
      _otherCharges.removeAt(index);
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final otherCharges = _otherCharges
          .where((c) => c.labelController.text.trim().isNotEmpty)
          .map((c) => {
                'label': c.labelController.text.trim(),
                'description': c.labelController.text.trim(),
                'amount': double.tryParse(c.amountController.text.trim()) ?? 0,
              })
          .toList();

      final result = await ApiService.bulkGenerateChallans({
        'className': _selectedClassName,
        'month': _selectedMonth,
        'year': _selectedYear,
        'dueDate': _dueDate.toIso8601String(),
        'otherCharges': otherCharges,
      });

      if (!mounted) return;

      final createdInfo =
          result['created'] != null ? ' (${result['created']} generated)' : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challans generated successfully$createdInfo')),
      );

      setState(() {
        for (final c in _otherCharges) {
          c.labelController.dispose();
          c.amountController.dispose();
        }
        _otherCharges.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate challans: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    for (final c in _otherCharges) {
      c.labelController.dispose();
      c.amountController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgLight,
      appBar: AppBar(
        title: const Text('Bulk Fee Challan Generation'),
        backgroundColor: AppColors.mintEmerald,
        foregroundColor: Colors.white,
      ),
      body: _loadingClasses
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: _formKey,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generate Challans for a Class',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textDarkColor),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedClassName,
                                dropdownColor: context.cardWhite,
                                style: TextStyle(color: context.textDarkColor),
                                decoration: _decoration('Select Class', context),
                                items: _classes.map<DropdownMenuItem<String>>((c) {
                                  final name = c['className']?.toString() ?? '';
                                  return DropdownMenuItem(value: name, child: Text(name));
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedClassName = v),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      initialValue: _selectedMonth,
                                      dropdownColor: context.cardWhite,
                                      style: TextStyle(color: context.textDarkColor),
                                      decoration: _decoration('Month', context),
                                      items: List.generate(12, (i) => i + 1)
                                          .map((m) => DropdownMenuItem(
                                                value: m,
                                                child: Text(_monthNames[m - 1]),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setState(() => _selectedMonth = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _selectedYear.toString(),
                                      style: TextStyle(color: context.textDarkColor),
                                      decoration: _decoration('Year', context),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) =>
                                          _selectedYear = int.tryParse(v) ?? _selectedYear,
                                      validator: (v) =>
                                          (v == null || v.isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _pickDueDate,
                                child: InputDecorator(
                                  decoration: _decoration('Due Date', context),
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(_dueDate),
                                    style: TextStyle(color: context.textDarkColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.cardWhite,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: context.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Other Charges (optional)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textDarkColor),
                                  ),
                                  TextButton.icon(
                                    onPressed: _addOtherCharge,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Charge'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_otherCharges.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'No extra charges added.',
                                    style: TextStyle(color: context.textGreyColor),
                                  ),
                                ),
                              ..._otherCharges.asMap().entries.map((entry) {
                                final index = entry.key;
                                final charge = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: charge.labelController,
                                          style: TextStyle(color: context.textDarkColor),
                                          decoration: _decoration('Description', context),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: charge.amountController,
                                          style: TextStyle(color: context.textDarkColor),
                                          decoration: _decoration('Amount', context),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.overdueCrimson),
                                        onPressed: () => _removeOtherCharge(index),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mintEmerald,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Generate Challans',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _decoration(String label, BuildContext context) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.textGreyColor),
      border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.mintEmerald)),
    );
  }
}

class _OtherCharge {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
}