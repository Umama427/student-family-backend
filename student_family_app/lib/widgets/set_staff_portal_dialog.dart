import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/staff_provider.dart';
import '../providers/class_provider.dart';
import '../utils/app_theme.dart';

class SetStaffPortalDialog extends StatefulWidget {
  final Map<String, dynamic> staff;

  const SetStaffPortalDialog({super.key, required this.staff});

  @override
  State<SetStaffPortalDialog> createState() => _SetStaffPortalDialogState();
}

class _SetStaffPortalDialogState extends State<SetStaffPortalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  late List<String> _selectedClasses;
  bool _isSubmitting = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.staff['email']?.toString() ?? '');
    final assigned = widget.staff['assignedClasses'];
    _selectedClasses = assigned is List ? List<String>.from(assigned.map((e) => e.toString())) : [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClassProvider>(context, listen: false).fetchClasses();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final provider = Provider.of<StaffProvider>(context, listen: false);
    final success = await provider.setPortalAccess(
      widget.staff['_id'].toString(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
      assignedClasses: _selectedClasses,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Portal access configured! 🎉'), backgroundColor: AppColors.mintEmerald),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: AppColors.overdueCrimson),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = Provider.of<ClassProvider>(context);
    final name = widget.staff['fullName']?.toString() ?? 'Staff';

    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
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
                    Expanded(
                      child: Text('Portal Access — $name',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textDarkColor)),
                    ),
                    IconButton(
                        icon: Icon(Icons.close, color: context.textGreyColor),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Set login email, password and assign classes so this teacher can access their portal.',
                  style: TextStyle(fontSize: 12.5, color: context.textGreyColor),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailCtrl,
                  style: TextStyle(color: context.textDarkColor),
                  decoration: InputDecoration(
                    labelText: 'Login Email *',
                    labelStyle: TextStyle(color: context.textGreyColor),
                    border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                    prefixIcon: Icon(Icons.email_outlined, color: context.textGreyColor),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Email is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: TextStyle(color: context.textDarkColor),
                  decoration: InputDecoration(
                    labelText: 'Password (leave blank to keep unchanged)',
                    labelStyle: TextStyle(color: context.textGreyColor),
                    border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
                    prefixIcon: Icon(Icons.lock_outline, color: context.textGreyColor),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: context.textGreyColor),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Assigned Classes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: context.textDarkColor)),
                const SizedBox(height: 8),
                classProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : classProvider.classes.isEmpty
                        ? Text('No classes available. Create a class first.',
                            style: TextStyle(color: context.textGreyColor, fontSize: 12.5))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: classProvider.classes.map<Widget>((c) {
                              final cls = Map<String, dynamic>.from(c);
                              final className = cls['className'].toString();
                              final selected = _selectedClasses.contains(className);
                              return FilterChip(
                                label: Text(className),
                                selected: selected,
                                backgroundColor: context.bgLight,
                                labelStyle: TextStyle(color: context.textDarkColor),
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedClasses.add(className);
                                    } else {
                                      _selectedClasses.remove(className);
                                    }
                                  });
                                },
                                selectedColor: AppColors.mintEmerald.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.mintEmerald,
                              );
                            }).toList(),
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
                          : const Text('Save Access', style: TextStyle(color: Colors.white)),
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