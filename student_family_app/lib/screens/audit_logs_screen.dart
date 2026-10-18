import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audit_log_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/action_badge.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final List<String> _modules = [
    'All',
    'Student',
    'Family',
    'Staff',
    'Salary',
    'Fee Challan',
    'Attendance',
    'Exam',
    'Result',
    'Student Progress',
  ];
  final List<String> _actions = ['All', 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuditLogProvider>(context, listen: false).fetchLogs();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditLogProvider>(
      builder: (context, provider, child) {
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
                      Text(
                        'Audit Logs',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.textDarkColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.totalCount} activities recorded',
                        style: TextStyle(color: context.textGreyColor, fontSize: 14),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => provider.fetchLogs(page: provider.currentPage),
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filters
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: context.cardShadow,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text('Filter by Module', style: TextStyle(color: context.textGreyColor)),
                          value: provider.moduleFilter,
                          dropdownColor: context.cardWhite,
                          style: TextStyle(color: context.textDarkColor),
                          items: _modules
                              .map((m) => DropdownMenuItem(
                                    value: m == 'All' ? null : m,
                                    child: Text(m),
                                  ))
                              .toList(),
                          onChanged: (value) => provider.setModuleFilter(value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: context.cardShadow,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text('Filter by Action', style: TextStyle(color: context.textGreyColor)),
                          value: provider.actionFilter,
                          dropdownColor: context.cardWhite,
                          style: TextStyle(color: context.textDarkColor),
                          items: _actions
                              .map((a) => DropdownMenuItem(
                                    value: a == 'All' ? null : a,
                                    child: Text(a),
                                  ))
                              .toList(),
                          onChanged: (value) => provider.setActionFilter(value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => provider.clearFilters(),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.mintEmerald))
                    : provider.logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded,
                                    size: 70, color: context.textGreyColor.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No activity logs found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.textDarkColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: provider.logs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final log = provider.logs[index];

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.cardWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: context.cardShadow,
                                ),
                                child: Row(
                                  children: [
                                    ActionBadge(action: log.action),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log.description,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: context.textDarkColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${log.module} • by ${log.userName}',
                                            style: TextStyle(fontSize: 12, color: context.textGreyColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatDate(log.createdAt),
                                      style: TextStyle(fontSize: 12, color: context.textGreyColor),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Pagination
              if (provider.totalPages > 1) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: provider.currentPage > 1 ? provider.previousPage : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      'Page ${provider.currentPage} of ${provider.totalPages}',
                      style: TextStyle(color: context.textDarkColor),
                    ),
                    IconButton(
                      onPressed: provider.currentPage < provider.totalPages ? provider.nextPage : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}