import 'package:flutter/material.dart';
import '../services/payment_export_service.dart';
import '../utils/app_theme.dart';

class ExportButton extends StatefulWidget {
  final String module;
  final String label;

  const ExportButton({super.key, required this.module, this.label = 'Export'});

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  bool _isLoading = false;

  Future<void> _export(String format) async {
    setState(() => _isLoading = true);
    try {
      await PaymentExportService.exportModule(widget.module, format);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.module} exported successfully (${format.toUpperCase()})'),
            backgroundColor: const Color(0xFF2ECC9A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: const Color(0xFFE63950)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: !_isLoading,
      onSelected: _export,
      color: context.cardWhite,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'excel', child: Text('Export to Excel (.xlsx)')),
        const PopupMenuItem(value: 'csv', child: Text('Export to CSV (.csv)')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.file_download_outlined, size: 18, color: context.textDarkColor),
            const SizedBox(width: 8),
            Text(widget.label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.textDarkColor)),
          ],
        ),
      ),
    );
  }
}