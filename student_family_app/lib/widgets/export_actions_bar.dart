import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class ExportActionsBar extends StatefulWidget {
  final String examId;
  final String examName;
  final String className;
  const ExportActionsBar({
    super.key,
    required this.examId,
    this.examName = 'Exam',
    this.className = 'Class',
  });

  @override
  State<ExportActionsBar> createState() => _ExportActionsBarState();
}

class _ExportActionsBarState extends State<ExportActionsBar> {
  bool isExcelLoading = false;
  bool isPdfLoading = false;

  Future<void> _exportExcel() async {
    setState(() => isExcelLoading = true);
    try {
      await ApiService.downloadExamResultsExcel(widget.examId, widget.examName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isExcelLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => isPdfLoading = true);
    try {
      await ApiService.downloadClassReportCards(widget.examId, widget.className);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report cards: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isPdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
          icon: isExcelLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.grid_on_rounded, color: Colors.white, size: 18),
          label: Text(isExcelLoading ? 'Exporting...' : 'Export to Excel',
              style: const TextStyle(color: Colors.white)),
          onPressed: isExcelLoading ? null : _exportExcel,
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.mintEmerald),
          icon: isPdfLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
          label: Text(isPdfLoading ? 'Generating...' : 'All Report Cards (PDF)',
              style: const TextStyle(color: Colors.white)),
          onPressed: isPdfLoading ? null : _exportPdf,
        ),
      ],
    );
  }
}