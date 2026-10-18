import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/add_exam_dialog.dart';
import 'exam_results_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String _searchQuery = '';
  String? _role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExamProvider>(context, listen: false).fetchExams();
    });
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService.getRole();
    if (mounted) {
      setState(() => _role = role);
    }
  }

  void _openAddDialog() {
    showDialog(context: context, builder: (_) => const AddExamDialog());
  }

  void _onExamTap(dynamic exam) {
    if (_role == 'parent') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Apne bachay ka result dekhne ke liye 'My Children' section mein jayein.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExamResultsScreen(exam: exam)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.mintEmerald;
      case 'Cancelled':
        return AppColors.coral;
      default:
        return AppColors.accentGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, provider, child) {
        final filtered = provider.exams
            .where((e) =>
                e.examName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.className.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exams & Results',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.textDarkColor)),
                        const SizedBox(height: 4),
                        Text('${provider.exams.length} exams created',
                            style: TextStyle(color: context.textGreyColor, fontSize: 14)),
                      ],
                    ),
                    if (_role != 'parent')
                      ElevatedButton.icon(
                        onPressed: _openAddDialog,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Create Exam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: context.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: context.cardShadow,
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(color: context.textDarkColor),
                    decoration: InputDecoration(
                      hintText: 'Search by exam name or class...',
                      hintStyle: TextStyle(color: context.textMutedColor),
                      prefixIcon: Icon(Icons.search_rounded, color: context.textGreyColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: context.cardWhite,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.mintEmerald))
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_rounded, size: 70, color: context.textGreyColor.withValues(alpha: 0.3)),
                                  const SizedBox(height: 16),
                                  Text('No exams found',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textDarkColor)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final exam = filtered[index];
                                final statusColor = _statusColor(exam.status);

                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _onExamTap(exam),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: context.cardWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: context.cardShadow,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.deepNavy.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.assignment_rounded, color: AppColors.deepNavy),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(exam.examName,
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textDarkColor)),
                                              const SizedBox(height: 2),
                                              Text('${exam.examType} • Class ${exam.className}',
                                                  style: TextStyle(fontSize: 12.5, color: context.textGreyColor)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Text('${exam.subjects.length} subjects',
                                              style: TextStyle(fontSize: 13, color: context.textDarkColor)),
                                        ),
                                        Expanded(
                                          child: Text(
                                              '${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}',
                                              style: TextStyle(fontSize: 13, color: context.textDarkColor)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            exam.status,
                                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.chevron_right_rounded, color: context.textGreyColor),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}