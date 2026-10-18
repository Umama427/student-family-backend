import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';
import '../utils/app_theme.dart';

class AddFamilyDialog extends StatefulWidget {
  const AddFamilyDialog({super.key});

  @override
  State<AddFamilyDialog> createState() => _AddFamilyDialogState();
}

class _AddFamilyDialogState extends State<AddFamilyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _familyNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _motherNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'familyName': _familyNameCtrl.text.trim(),
      'fatherName': _fatherNameCtrl.text.trim(),
      'motherName': _motherNameCtrl.text.trim(),
      'primaryPhone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    };

    final provider = Provider.of<FamilyProvider>(context, listen: false);
    final success = await provider.addFamily(data);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Family added successfully! 🎉'),
          backgroundColor: AppColors.mintEmerald,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.errorMessage ?? "Something went wrong"}'),
          backgroundColor: AppColors.overdueCrimson,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 480,
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
                        gradient: AppColors.mintGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.family_restroom_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Add New Family',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textDarkColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildField(context, _familyNameCtrl, 'Family Name', Icons.badge_outlined, required: true),
                const SizedBox(height: 14),
                _buildField(context, _fatherNameCtrl, "Father's Name", Icons.man_rounded, required: true),
                const SizedBox(height: 14),
                _buildField(context, _motherNameCtrl, "Mother's Name (Optional)", Icons.woman_rounded),
                const SizedBox(height: 14),
                _buildField(context, _phoneCtrl, 'Primary Phone (03XXXXXXXXX)', Icons.phone_rounded,
                    required: true, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildField(context, _emailCtrl, 'Email (Optional)', Icons.email_outlined),
                const SizedBox(height: 14),
                _buildField(context, _addressCtrl, 'Address (Optional)', Icons.location_on_outlined, maxLines: 2),

                const SizedBox(height: 26),

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
                            ? const SizedBox(
                                height: 18, width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Save Family'),
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
  }

  Widget _buildField(
    BuildContext context,
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: context.textDarkColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.textGreyColor),
        prefixIcon: Icon(icon, size: 20, color: context.textGreyColor),
        filled: true,
        fillColor: context.bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }
}