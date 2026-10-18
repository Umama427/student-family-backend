import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _type = 'student';
  String? _selectedClass;
  String? _role;

  List<dynamic> _classes = [];
  List<dynamic> _roster = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final role = await AuthService.getRole();
    setState(() => _role = role);

    if (role == 'admin') {
      try {
        final classes = await ApiService.getClasses();
        setState(() => _classes = classes);
      } catch (_) {}
    } else if (role == 'teacher') {
      final assigned = await AuthService.getAssignedClasses();
      setState(() => _classes = assigned.map((c) => {'className': c}).toList());
    }

    await _loadRoster();
  }

  Future<void> _loadRoster() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getAttendanceRoster(
        type: _type,
        className: _selectedClass,
        date: _selectedDate,
      );
      setState(() {
        _roster = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Attendance load nahi ho saki: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadRoster();
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Leave':
        return Colors.blue;
      case 'Late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: context.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.mintEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Attendance History'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadRoster),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(dateLabel),
                ),
                if (_role == 'admin')
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: context.cardWhite,
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        labelText: 'Type',
                        labelStyle: TextStyle(color: context.textGreyColor),
                      ),
                      dropdownColor: context.cardWhite,
                      style: TextStyle(color: context.textDarkColor),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Students')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _type = v!;
                          _selectedClass = null;
                        });
                        _loadRoster();
                      },
                    ),
                  ),
                if (_type == 'student' && (_role == 'admin' || _role == 'teacher'))
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: context.cardWhite,
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        labelText: 'Class',
                        labelStyle: TextStyle(color: context.textGreyColor),
                      ),
                      dropdownColor: context.cardWhite,
                      style: TextStyle(color: context.textDarkColor),
                      items: _classes
                          .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                                value: c['className'],
                                child: Text(c['className'] ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedClass = v);
                        _loadRoster();
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: AppText.body.copyWith(color: context.textGreyColor),
                          ),
                        )
                      : _roster.isEmpty
                          ? Center(
                              child: Text(
                                'Is din ka koi record nahi mila.',
                                style: TextStyle(color: context.textGreyColor),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _roster.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final r = _roster[index];
                                final status = r['status'];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: context.cardWhite,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(color: context.borderColor),
                                    boxShadow: context.cardShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.mintEmerald.withValues(alpha: 0.15),
                                        child: Text(
                                          (r['name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                          style: const TextStyle(color: AppColors.mintEmerald, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          r['name'] ?? '',
                                          style: AppText.bodyBold.copyWith(color: context.textDarkColor),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status ?? 'Not Marked',
                                          style: TextStyle(
                                            color: status == null ? context.textMutedColor : _statusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}