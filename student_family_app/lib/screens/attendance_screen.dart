import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../providers/student_provider.dart';
import '../providers/staff_provider.dart';
import '../services/auth_service.dart'; // ✅ ADDED
import '../utils/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _type = 'student';
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _pendingStatus = {};
  bool _isSaving = false;
  String _userRole = 'admin'; // ✅ ADDED

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ Role pehle load karo
      _userRole = await AuthService.getRole() ?? 'admin';

      Provider.of<StudentProvider>(context, listen: false).fetchStudents();

      // ✅ Staff list sirf Admin ke liye fetch karo (403 avoid karne ke liye)
      if (_userRole == 'admin') {
        Provider.of<StaffProvider>(context, listen: false).fetchStaff();
      }

      _loadAttendance();
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadAttendance() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    await provider.fetchAttendance(
      type: _type,
      month: _selectedDate.month,
      year: _selectedDate.year,
    );
    _syncPendingFromRecords();
  }

  void _syncPendingFromRecords() {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    _pendingStatus.clear();
    for (final r in provider.records) {
      if (r.date.year == _selectedDate.year &&
          r.date.month == _selectedDate.month &&
          r.date.day == _selectedDate.day) {
        _pendingStatus[r.refIdString] = r.status;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadAttendance();
    }
  }

  void _switchType(String type) {
    // ✅ Non-admin ko staff type select karne hi nahi dena
    if (type == 'staff' && _userRole != 'admin') return;
    if (_type == type) return;
    setState(() => _type = type);
    _loadAttendance();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Present':
        return AppColors.paidGreen;
      case 'Absent':
        return AppColors.overdueCrimson;
      case 'Leave':
        return AppColors.sky;
      case 'Late':
        return AppColors.accentGold;
      default:
        return AppColors.textGrey;
    }
  }

  List<Map<String, String>> _getPeopleList(List<dynamic> rawList) {
    return rawList.map<Map<String, String>>((p) {
      if (p is Map) {
        return {
          'id': (p['_id'] ?? '').toString(),
          'name': (p['fullName'] ?? p['name'] ?? '').toString(),
        };
      } else {
        return {
          'id': p.id as String,
          'name': p.fullName as String,
        };
      }
    }).toList();
  }

  Future<void> _saveAttendance(List<Map<String, String>> people) async {
    setState(() => _isSaving = true);
    final provider = Provider.of<AttendanceProvider>(context, listen: false);

    final records = people.map((p) {
      final id = p['id']!;
      final status = _pendingStatus[id] ?? 'Present';
      return {'refId': id, 'status': status, 'remarks': ''};
    }).toList();

    final success = await provider.saveBulkAttendance(
      type: _type,
      date: _selectedDate,
      records: records,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Attendance saved successfully! ✅'),
            backgroundColor: AppColors.mintEmerald),
      );
      _loadAttendance();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${provider.errorMessage}'),
            backgroundColor: AppColors.overdueCrimson),
      );
    }
  }

  // ✅ Parent read-only hai, Admin/Teacher edit kar sakte hain
  bool get _canEdit => _userRole == 'admin' || _userRole == 'teacher';

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudentProvider, StaffProvider>(
      builder: (context, studentProvider, staffProvider, child) {
        final rawList =
            _type == 'student' ? studentProvider.students : staffProvider.staffList;
        final people = _getPeopleList(rawList);

        return Padding(
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
                      const Text('Attendance',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: const Text('Change Date'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ✅ Save button sirf Admin/Teacher ko dikhega
                      if (_canEdit)
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _saveAttendance(people),
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Save Attendance'),
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
                ],
              ),
              const SizedBox(height: 20),

              // ✅ Type Toggle — Staff tab sirf Admin ko dikhega
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    _buildTypeTab('Students', 'student'),
                    if (_userRole == 'admin') _buildTypeTab('Staff', 'staff'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: Consumer<AttendanceProvider>(
                  builder: (context, attendanceProvider, _) {
                    if (attendanceProvider.isLoading) {
                      return const Center(
                          child: CircularProgressIndicator(color: AppColors.mintEmerald));
                    }
                    if (people.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_rounded,
                                size: 70, color: AppColors.textGrey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('No ${_type == 'student' ? 'students' : 'staff'} found',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: people.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final person = people[index];
                        final id = person['id']!;
                        final name = person['name']!;
                        final currentStatus = _pendingStatus[id] ?? 'Present';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.deepNavy.withOpacity(0.1),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                      color: AppColors.deepNavy, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(name,
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                              // ✅ Parent ke liye status sirf badge (non-clickable)
                              if (!_canEdit)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _statusColor(currentStatus).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    currentStatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(currentStatus),
                                    ),
                                  ),
                                )
                              else
                                ...['Present', 'Absent', 'Leave', 'Late'].map((status) {
                                  final selected = currentStatus == status;
                                  final color = _statusColor(status);
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: GestureDetector(
                                      onTap: () => setState(() => _pendingStatus[id] = status),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: selected ? color : color.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                              color: color.withOpacity(selected ? 1 : 0.3)),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: selected ? Colors.white : color,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeTab(String label, String value) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchType(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.deepNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textGrey,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}