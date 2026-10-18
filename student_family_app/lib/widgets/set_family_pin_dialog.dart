import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';
import '../utils/app_theme.dart';

class SetFamilyPinDialog extends StatefulWidget {
  final String familyId;
  final String familyName;

  const SetFamilyPinDialog({super.key, required this.familyId, required this.familyName});

  @override
  State<SetFamilyPinDialog> createState() => _SetFamilyPinDialogState();
}

class _SetFamilyPinDialogState extends State<SetFamilyPinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final provider = Provider.of<FamilyProvider>(context, listen: false);
    final success = await provider.setFamilyPin(widget.familyId, _pinCtrl.text.trim());

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Portal PIN updated! 🎉'), backgroundColor: AppColors.mintEmerald),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: AppColors.overdueCrimson),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
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
                  Expanded(
                    child: Text('Set Portal PIN — ${widget.familyName}',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textDarkColor)),
                  ),
                  IconButton(
                      icon: Icon(Icons.close, color: context.textGreyColor),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This family will use their Primary Phone + this PIN to login on the Parent Portal.',
                style: TextStyle(fontSize: 12.5, color: context.textGreyColor),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: TextStyle(color: context.textDarkColor),
                decoration: InputDecoration(
                  labelText: '4-digit PIN *',
                  labelStyle: TextStyle(color: context.textGreyColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                  prefixIcon: Icon(Icons.pin_outlined, color: context.textGreyColor),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().length != 4) return 'Enter exactly 4 digits';
                  if (int.tryParse(v.trim()) == null) return 'PIN must be numeric';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: context.textDarkColor))),
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
                        : const Text('Save PIN', style: TextStyle(color: Colors.white)),
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