import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/add_notification_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _filterAudience;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  void _applyFilters() {
    Provider.of<NotificationProvider>(context, listen: false)
        .fetchNotifications(audience: _filterAudience, type: _filterType);
  }

  void _openAddDialog() {
    showDialog(context: context, builder: (_) => const AddNotificationDialog());
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'emergency':
        return AppColors.overdueCrimson;
      case 'fee':
        return AppColors.accentGold;
      case 'attendance':
        return AppColors.sky;
      default:
        return AppColors.mintEmerald;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'emergency':
        return Icons.warning_rounded;
      case 'fee':
        return Icons.receipt_long_rounded;
      case 'attendance':
        return Icons.fact_check_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
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
                        'Notifications',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.textDarkColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.notifications.length} notifications',
                        style: TextStyle(color: context.textGreyColor, fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openAddDialog,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('New Notification'),
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

              // Filters
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      context: context,
                      label: 'Audience',
                      value: _filterAudience,
                      items: const ['all', 'students', 'staff', 'families'],
                      onChanged: (v) {
                        setState(() => _filterAudience = v);
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      context: context,
                      label: 'Type',
                      value: _filterType,
                      items: const ['general', 'emergency', 'fee', 'attendance'],
                      onChanged: (v) {
                        setState(() => _filterType = v);
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.mintEmerald))
                    : provider.notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_rounded,
                                    size: 70, color: context.textGreyColor.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No notifications found',
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
                            itemCount: provider.notifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final n = provider.notifications[index];
                              final color = _typeColor(n.type);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.cardWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: n.isRead
                                      ? null
                                      : Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                                  boxShadow: context.cardShadow,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_typeIcon(n.type), color: color, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(n.title,
                                                    style: TextStyle(
                                                        fontWeight: n.isRead
                                                            ? FontWeight.w600
                                                            : FontWeight.bold,
                                                        fontSize: 15,
                                                        color: context.textDarkColor)),
                                              ),
                                              if (!n.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      BoxDecoration(color: color, shape: BoxShape.circle),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(n.message,
                                              style: TextStyle(fontSize: 13, color: context.textGreyColor)),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(n.type.toUpperCase(),
                                                    style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: color)),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: context.textGreyColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(n.audience.toUpperCase(),
                                                    style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: context.textGreyColor)),
                                              ),
                                              const Spacer(),
                                              Text(DateFormat('d MMM, h:mm a').format(n.createdAt),
                                                  style: TextStyle(
                                                      fontSize: 11, color: context.textGreyColor)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        if (!n.isRead)
                                          IconButton(
                                            icon: const Icon(Icons.mark_email_read_rounded, size: 20),
                                            color: AppColors.mintEmerald,
                                            tooltip: 'Mark as read',
                                            onPressed: () => provider.markAsRead(n.id),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                          color: AppColors.overdueCrimson,
                                          tooltip: 'Delete',
                                          onPressed: () => provider.removeNotification(n.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: context.cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: context.cardShadow,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: context.cardWhite,
        style: TextStyle(color: context.textDarkColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textGreyColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          DropdownMenuItem<String>(value: null, child: Text('All ${label}s')),
          ...items.map((e) => DropdownMenuItem<String>(value: e, child: Text(e.toUpperCase()))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}