import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _selectedSubject;
  String? _role;
  bool _loadingRole = true;
  bool _sending = false;

  final List<String> _subjects = [
    'Fee / Challan Issue',
    'Attendance Issue',
    'Exam / Result Issue',
    'Technical Problem',
    'Other',
  ];

  // 🔧 School contact info — zaroorat ho to yahan change kar dein
  static const String supportPhone = '0333 1332543';
  static const String supportEmail = 'support@edumanage.com';
  static const String supportAddress = 'EduManage School, Main Campus';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final role = await AuthService.getRole();
    final name = await AuthService.getUserName();
    setState(() {
      _role = role;
      _nameController.text = name ?? '';
      _loadingRole = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:$supportPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp() async {
    final cleanNumber = supportPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/92${cleanNumber.substring(1)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:$supportEmail');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      await ApiService.sendSupportMessage({
        'senderName': _nameController.text.trim(),
        'senderEmail': _emailController.text.trim(),
        'subject': _selectedSubject,
        'message': _messageController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message bhej diya gaya. Hum jald rabta karenge.')),
        );
        _messageController.clear();
        setState(() => _selectedSubject = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message bhejne mein masla hua: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roleLabel = _role == 'teacher' ? 'Teacher Support' : 'Parent Support';

    return Scaffold(
      backgroundColor: context.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.mintEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(roleLabel),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final cards = [
                  _buildContactCard(
                    context: context,
                    icon: Icons.phone_rounded,
                    iconColor: Colors.blue,
                    title: 'Call / WhatsApp',
                    value: supportPhone,
                    subtitle: 'Mon-Sat (9am - 6pm)',
                    primaryButtonLabel: 'Call Now',
                    onPrimaryTap: _launchPhone,
                    secondaryButtonLabel: 'WhatsApp',
                    onSecondaryTap: _launchWhatsApp,
                  ),
                  _buildContactCard(
                    context: context,
                    icon: Icons.email_rounded,
                    iconColor: Colors.red,
                    title: 'Email Us',
                    value: supportEmail,
                    subtitle: "We'll respond within 24 hours",
                    primaryButtonLabel: 'Send Email',
                    onPrimaryTap: _launchEmail,
                  ),
                  _buildContactCard(
                    context: context,
                    icon: Icons.location_on_rounded,
                    iconColor: Colors.green,
                    title: 'Visit Us',
                    value: supportAddress,
                    subtitle: '',
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: cards
                        .map((c) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: c,
                              ),
                            ))
                        .toList(),
                  );
                }
                return Column(
                  children: cards
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: c,
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final form = _buildMessageForm(context);
                final faq = _buildFaqAndHours(context);

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: form),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: faq),
                    ],
                  );
                }
                return Column(children: [form, const SizedBox(height: 20), faq]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    String? primaryButtonLabel,
    VoidCallback? onPrimaryTap,
    String? secondaryButtonLabel,
    VoidCallback? onSecondaryTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.cardShadow,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: iconColor.withValues(alpha: 0.1),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppText.bodyBold.copyWith(color: context.textDarkColor)),
          const SizedBox(height: 6),
          Text(value, textAlign: TextAlign.center, style: AppText.body.copyWith(color: context.textGreyColor)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppText.caption.copyWith(color: context.textMutedColor),
              textAlign: TextAlign.center,
            ),
          ],
          if (primaryButtonLabel != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: onPrimaryTap, child: Text(primaryButtonLabel)),
            ),
          ],
          if (secondaryButtonLabel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: onSecondaryTap, child: Text(secondaryButtonLabel)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.cardShadow,
        border: Border.all(color: context.borderColor),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.send_rounded, color: AppColors.mintEmerald, size: 20),
                const SizedBox(width: 8),
                Text('Send us a Message', style: AppText.bodyBold.copyWith(color: context.textDarkColor)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: context.textDarkColor),
                    decoration: _decoration('Your Name', context),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Naam zaroori hai' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: context.textDarkColor),
                    decoration: _decoration('Email Address', context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              dropdownColor: context.cardWhite,
              style: TextStyle(color: context.textDarkColor),
              decoration: _decoration('Subject', context),
              items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _selectedSubject = v),
              validator: (v) => v == null ? 'Subject select karein' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              style: TextStyle(color: context.textDarkColor),
              decoration: _decoration('Message', context, hint: 'Describe your query in detail...'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Message likhna zaroori hai' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mintEmerald,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _sending
                      ? null
                      : () {
                          _messageController.clear();
                          setState(() => _selectedSubject = null);
                        },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, BuildContext context, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: hint != null,
      labelStyle: TextStyle(color: context.textGreyColor),
      hintStyle: TextStyle(color: context.textMutedColor),
      border: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.borderColor)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.mintEmerald)),
    );
  }

  Widget _buildFaqAndHours(BuildContext context) {
    final faqs = _role == 'teacher'
        ? const [
            {'q': 'Attendance kaise mark karein?', 'a': 'Sidebar mein "Attendance" pe jayein, apni class select karein, har student ka status select karke Save Attendance dabayein.'},
            {'q': 'Result kaise enter karein?', 'a': '"Bulk Result Entry" screen se apni assigned exam aur subject select karke marks enter karein.'},
            {'q': 'Password bhool gaye?', 'a': 'Login screen par "Forgot Password" option use karein ya admin se rabta karein.'},
          ]
        : const [
            {'q': 'Fee challan kaise download karein?', 'a': '"Fee Challans" section mein jayein, relevant month select karke download/print karein.'},
            {'q': 'Result kahan dekhein?', 'a': '"My Children" se apne bachay ko select karein, phir "Results" tab kholein.'},
            {'q': 'Attendance kaise check karein?', 'a': '"My Children" se bachay ko select karke "Attendance" tab dekhein.'},
          ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardWhite,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: context.cardShadow,
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_rounded, color: AppColors.mintEmerald, size: 20),
                  const SizedBox(width: 8),
                  Text('Frequently Asked', style: AppText.bodyBold.copyWith(color: context.textDarkColor)),
                ],
              ),
              const SizedBox(height: 8),
              ...faqs.map((f) => ExpansionTile(
                    title: Text(f['q']!, style: AppText.body.copyWith(color: context.textDarkColor)),
                    collapsedIconColor: context.textGreyColor,
                    iconColor: AppColors.mintEmerald,
                    childrenPadding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(f['a']!, style: AppText.caption.copyWith(color: context.textMutedColor)),
                      ),
                    ],
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardWhite,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: context.cardShadow,
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.mintEmerald, size: 20),
                  const SizedBox(width: 8),
                  Text('Support Hours', style: AppText.bodyBold.copyWith(color: context.textDarkColor)),
                ],
              ),
              const SizedBox(height: 12),
              _hourRow(context, 'Monday - Friday', '9:00 AM - 6:00 PM'),
              _hourRow(context, 'Saturday', '9:00 AM - 2:00 PM'),
              _hourRow(context, 'Sunday', 'Closed', isClosed: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hourRow(BuildContext context, String day, String time, {bool isClosed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: AppText.body.copyWith(color: context.textGreyColor)),
          Text(
            time,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isClosed ? AppColors.overdueCrimson : context.textDarkColor,
            ),
          ),
        ],
      ),
    );
  }
}