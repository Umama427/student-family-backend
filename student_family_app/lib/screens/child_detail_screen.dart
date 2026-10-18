import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

class ChildDetailScreen extends StatefulWidget {
  final dynamic child;
  const ChildDetailScreen({super.key, required this.child});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  List<dynamic> _attendance = [];
  List<dynamic> _challans = [];
  List<dynamic> _results = [];
  final Set<String> _downloadingExamIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _studentId =>
      widget.child['_id']?.toString() ?? widget.child['id']?.toString() ?? '';
  String get _studentName => widget.child['fullName']?.toString() ?? 'Student';

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final attendance = await ApiService.getChildAttendance(_studentId);
      final challans = await ApiService.getChildChallans(_studentId);
      final results = await ApiService.getChildResults(_studentId);

      if (!mounted) return;
      setState(() {
        _attendance = attendance;
        _challans = challans;
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  String _resultExamId(dynamic result) {
    final e = result['examId'];
    if (e is Map) return e['_id']?.toString() ?? '';
    return e?.toString() ?? '';
  }

  String _resultExamName(dynamic result) {
    final e = result['examId'];
    if (e is Map) return e['examName']?.toString() ?? 'Exam';
    return 'Exam';
  }

  Future<void> _downloadReportCard(dynamic result) async {
    final examId = _resultExamId(result);
    if (examId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam info missing for this result')),
      );
      return;
    }

    setState(() => _downloadingExamIds.add(examId));
    try {
      await ApiService.downloadStudentReportCard(_studentId, examId, _studentName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report card downloaded')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download report card: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloadingExamIds.remove(examId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rollNumber = widget.child['rollNumber']?.toString() ?? '-';
    final className = widget.child['className']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(_studentName),
        backgroundColor: AppColors.mintEmerald,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Attendance'),
            Tab(text: 'Fee Challans'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.mintEmerald.withValues(alpha: 0.15),
                        child: Text(
                          _studentName.isNotEmpty ? _studentName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mintEmerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _studentName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Roll No: $rollNumber   |   Class: $className'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAttendanceTab(),
                      _buildChallansTab(),
                      _buildResultsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendance.isEmpty) {
      return const Center(child: Text('No attendance records found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendance.length,
      itemBuilder: (context, index) {
        final record = _attendance[index];
        final status = record['status']?.toString() ?? '-';
        final dateStr = record['date']?.toString();
        String formattedDate = dateStr ?? '-';
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          if (date != null) {
            formattedDate = DateFormat('dd MMM yyyy').format(date);
          }
        }
        final isPresent = status.toLowerCase() == 'present';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isPresent ? Colors.green : Colors.red).withValues(alpha: 0.15),
              child: Icon(
                isPresent ? Icons.check : Icons.close,
                color: isPresent ? Colors.green : Colors.red,
              ),
            ),
            title: Text(formattedDate),
            trailing: Text(
              status,
              style: TextStyle(
                color: isPresent ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChallansTab() {
    if (_challans.isEmpty) {
      return const Center(child: Text('No fee challans found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _challans.length,
      itemBuilder: (context, index) {
        final challan = _challans[index];
        final month = challan['month'];
        final year = challan['year']?.toString() ?? '-';
        final monthName = (month is int && month >= 1 && month <= 12)
            ? _monthNames[month - 1]
            : month.toString();
        final status = challan['status']?.toString() ?? '-';
        final totalPayable = challan['totalPayable']?.toString() ?? '0';

        Color statusColor;
        switch (status) {
          case 'Paid':
            statusColor = Colors.green;
            break;
          case 'Overdue':
            statusColor = Colors.red;
            break;
          case 'Partial':
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(Icons.receipt_long, color: statusColor),
            ),
            title: Text('$monthName $year'),
            subtitle: Text('Total Payable: Rs. $totalPayable'),
            trailing: Chip(
              label: Text(status, style: const TextStyle(color: Colors.white)),
              backgroundColor: statusColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsTab() {
    if (_results.isEmpty) {
      return const Center(child: Text('No results found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final percentage = result['percentage']?.toString() ?? '-';
        final grade = result['overallGrade']?.toString() ?? '-';
        final status = result['status']?.toString() ?? '-';
        final isPass = status == 'Pass';
        final examId = _resultExamId(result);
        final examName = _resultExamName(result);
        final isDownloading = _downloadingExamIds.contains(examId);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isPass ? Colors.green : Colors.red).withValues(alpha: 0.15),
              child: Text(
                grade,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPass ? Colors.green : Colors.red,
                ),
              ),
            ),
            title: Text(examName),
            subtitle: Text('Percentage: $percentage%   |   Status: $status'),
            trailing: IconButton(
              icon: isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              onPressed: isDownloading ? null : () => _downloadReportCard(result),
              tooltip: 'Download Report Card',
            ),
          ),
        );
      },
    );
  }
}