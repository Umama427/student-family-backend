import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../utils/app_theme.dart';

class AddNotificationDialog extends StatefulWidget {
  const AddNotificationDialog({super.key});

  @override
  State<AddNotificationDialog> createState() => _AddNotificationDialogState();
}

class _AddNotificationDialogState extends State<AddNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _type = 'general';
  String _audience = 'all';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await provider.addNotification(
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      type: _type,
      audience: _audience,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Notification sent successfully! 📢'),
            backgroundColor: AppColors.mintEmerald),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${provider.errorMessage}'),
            backgroundColor: AppColors.overdueCrimson),
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
                        gradient: AppColors.navyGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Text('New Notification',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textDarkColor)),
                  ],
                ),
                const SizedBox(height: 24),

                _buildField(context, _titleCtrl, 'Title', Icons.title_rounded, required: true),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _messageCtrl,
                  maxLines: 4,
                  style: TextStyle(color: context.textDarkColor),
                  decoration: InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(color: context.textGreyColor),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: context.bgLight,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Message is required' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        dropdownColor: context.cardWhite,
                        style: TextStyle(color: context.textDarkColor),
                        decoration: InputDecoration(
                          labelText: 'Type',
                          labelStyle: TextStyle(color: context.textGreyColor),
                          filled: true,
                          fillColor: context.bgLight,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                          DropdownMenuItem(value: 'fee', child: Text('Fee')),
                          DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
                        ],
                        onChanged: (value) => setState(() => _type = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _audience,
                        dropdownColor: context.cardWhite,
                        style: TextStyle(color: context.textDarkColor),
                        decoration: InputDecoration(
                          labelText: 'Audience',
                          labelStyle: TextStyle(color: context.textGreyColor),
                          filled: true,
                          fillColor: context.bgLight,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'students', child: Text('Students')),
                          DropdownMenuItem(value: 'staff', child: Text('Staff')),
                          DropdownMenuItem(value: 'families', child: Text('Families')),
                        ],
                        onChanged: (value) => setState(() => _audience = value!),
                      ),
                    ),
                  ],
                ),
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
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Send Notification'),
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

  Widget _buildField(BuildContext context, TextEditingController ctrl, String label, IconData icon,
      {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      style: TextStyle(color: context.textDarkColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.textGreyColor),
        prefixIcon: Icon(icon, size: 20, color: context.textGreyColor),
        filled: true,
        fillColor: context.bgLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }
}