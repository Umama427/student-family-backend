import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/family_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final _messageCtrl = TextEditingController();
  String _type = 'general';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FamilyProvider>(context, listen: false).fetchFamilies();
    });
  }

  Future<void> _sendBulk() async {
    if (_messageCtrl.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      final result = await ApiService.getBulkAnnouncementLinks(_messageCtrl.text.trim(), _type);
      final links = result['links'] as List<dynamic>;
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${links.length} WhatsApp links generated. Tap each family to send.'),
            backgroundColor: AppColors.mintEmerald,
          ),
        );
        _showLinksSheet(links);
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.overdueCrimson),
        );
      }
    }
  }

  void _showLinksSheet(List<dynamic> links) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send To Families',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textDarkColor)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: links.length,
                  separatorBuilder: (_, __) => Divider(color: context.borderColor),
                  itemBuilder: (context, i) {
                    final item = links[i];
                    return ListTile(
                      leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                      title: Text(item['familyName'] ?? '', style: TextStyle(color: context.textDarkColor)),
                      subtitle: Text(item['phone'] ?? '', style: TextStyle(color: context.textGreyColor)),
                      onTap: () async {
                        final uri = Uri.parse(item['link']);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Announcements',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.textDarkColor)),
          const SizedBox(height: 4),
          Text('Send announcements to all families via WhatsApp',
              style: TextStyle(color: context.textGreyColor, fontSize: 14)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: context.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: context.cardWhite,
                  style: TextStyle(color: context.textDarkColor),
                  decoration: InputDecoration(
                    labelText: 'Announcement Type',
                    labelStyle: TextStyle(color: context.textGreyColor),
                    filled: true,
                    fillColor: context.bgLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  style: TextStyle(color: context.textDarkColor),
                  decoration: InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(color: context.textGreyColor),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: context.bgLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendBulk,
                    icon: _isSending
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSending ? 'Generating Links...' : 'Send to All Families'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}