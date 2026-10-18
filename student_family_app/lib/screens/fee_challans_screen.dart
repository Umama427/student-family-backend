import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/fee_provider.dart';
import '../models/fee_challan_model.dart';
import '../services/api_service.dart';
import '../services/payment_export_service.dart';
import '../utils/app_theme.dart';
import '../widgets/add_challan_dialog.dart';
import '../widgets/mark_paid_dialog.dart';
import '../widgets/role_guard.dart';
import '../widgets/export_button.dart';

class FeeChallansScreen extends StatefulWidget {
  const FeeChallansScreen({super.key});

  @override
  State<FeeChallansScreen> createState() => _FeeChallansScreenState();
}

class _FeeChallansScreenState extends State<FeeChallansScreen> {
  String _activeFilter = 'All';
  bool _isApplyingPenalty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<FeeProvider>(context, listen: false).fetchChallans();
      _checkPaymentReturn();
    });
  }

  Future<void> _checkPaymentReturn() async {
    final uri = Uri.base;
    final payment = uri.queryParameters['payment'];
    final sessionId = uri.queryParameters['session_id'];

    if (payment == 'success' && sessionId != null && sessionId.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifying your payment...')),
      );
      try {
        final result = await PaymentExportService.verifyStripeSession(sessionId);
        if (!mounted) return;

        if (result['status'] == 'Paid') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Payment successful! Challan marked as Paid.'),
              backgroundColor: AppColors.paidGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment is still processing. Please refresh shortly.'),
              backgroundColor: AppColors.pendingAmber,
            ),
          );
        }
        Provider.of<FeeProvider>(context, listen: false).fetchChallans();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not verify payment: $e'), backgroundColor: AppColors.overdueCrimson),
          );
        }
      }
    } else if (payment == 'cancel') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment was cancelled.'), backgroundColor: AppColors.textGrey),
      );
    }
  }

  void _openAddDialog() {
    showDialog(context: context, builder: (_) => const AddChallanDialog());
  }

  void _openMarkPaidDialog(FeeChallanModel challan) {
    showDialog(context: context, builder: (_) => MarkPaidDialog(challan: challan));
  }

  Future<void> _downloadPdf(Future<void> Function() download) async {
    try {
      await download();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF error: $e'),
            backgroundColor: AppColors.overdueCrimson,
          ),
        );
      }
    }
  }

  Future<void> _sendWhatsAppReminder(FeeChallanModel challan) async {
    try {
      final result = challan.status == 'Paid'
          ? await ApiService.getPaymentConfirmationLink(challan.id)
          : await ApiService.getFeeReminderLink(challan.id);

      final link = result['link'];
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp link error: $e'), backgroundColor: AppColors.overdueCrimson),
        );
      }
    }
  }

  Future<void> _applyPenalty() async {
    setState(() => _isApplyingPenalty = true);
    try {
      final result = await ApiService.applyPenaltyOnOverdue(penaltyAmount: 500);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Penalty applied successfully'),
            backgroundColor: AppColors.accentGold,
          ),
        );
        Provider.of<FeeProvider>(context, listen: false).fetchChallans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.overdueCrimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplyingPenalty = false);
    }
  }

  Future<void> _openPaymentOptions(FeeChallanModel challan) async {
    final remaining = challan.totalPayable - challan.paidAmount;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.cardWhite,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ctx.textDarkColor)),
              const SizedBox(height: 6),
              Text(
                'Remaining: Rs. ${remaining.toStringAsFixed(0)}',
                style: TextStyle(color: ctx.textGreyColor),
              ),
              const SizedBox(height: 20),
              _paymentMethodTile(
                icon: Icons.credit_card_rounded,
                label: 'Pay with Card (Stripe)',
                color: const Color(0xFF635BFF),
                onTap: () {
                  Navigator.pop(ctx);
                  _payWithStripe(challan);
                },
              ),
              const SizedBox(height: 10),
              _paymentMethodTile(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Pay with JazzCash',
                color: const Color(0xFFED1C24),
                onTap: () async {
                  Navigator.pop(ctx);
                  final url = await PaymentExportService.getJazzCashRedirectUrl(challan.id);
                  _payWithRedirect(url);
                },
              ),
              const SizedBox(height: 10),
              _paymentMethodTile(
                icon: Icons.phone_android_rounded,
                label: 'Pay with EasyPaisa',
                color: const Color(0xFF0F9D58),
                onTap: () async {
                  Navigator.pop(ctx);
                  final url = await PaymentExportService.getEasyPaisaRedirectUrl(challan.id);
                  _payWithRedirect(url);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentMethodTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _payWithStripe(FeeChallanModel challan) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating secure Stripe checkout...')),
      );
      final url = await PaymentExportService.createStripeCheckout(challan.id);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          webOnlyWindowName: '_self',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stripe error: $e'), backgroundColor: AppColors.overdueCrimson),
        );
      }
    }
  }

  Future<void> _payWithRedirect(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        webOnlyWindowName: '_self',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeeProvider>(
      builder: (context, provider, child) {
        List<FeeChallanModel> displayList;
        switch (_activeFilter) {
          case 'Paid':
            displayList = provider.paidChallans;
            break;
          case 'Pending':
            displayList = provider.pendingChallans;
            break;
          case 'Overdue':
            displayList = provider.overdueChallans;
            break;
          default:
            displayList = provider.challans;
        }

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
                        Text('Fee Challans',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.textDarkColor)),
                        const SizedBox(height: 4),
                        Text('${provider.challans.length} total challans',
                            style: TextStyle(color: context.textGreyColor, fontSize: 14)),
                      ],
                    ),
                    Row(
                      children: [
                        RoleGuard(
                          allowedRoles: const ['admin'],
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: ExportButton(module: 'challans', label: 'Export'),
                          ),
                        ),
                        RoleGuard(
                          allowedRoles: const ['admin'],
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: OutlinedButton.icon(
                              onPressed: _isApplyingPenalty ? null : _applyPenalty,
                              icon: _isApplyingPenalty
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          color: AppColors.overdueCrimson, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.warning_amber_rounded, size: 18),
                              label: const Text('Apply Penalty'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.overdueCrimson,
                                side: const BorderSide(color: AppColors.overdueCrimson),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                        RoleGuard(
                          allowedRoles: const ['admin'],
                          child: ElevatedButton.icon(
                            onPressed: _openAddDialog,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Create Challan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    _filterChip('All', provider.challans.length),
                    const SizedBox(width: 10),
                    _filterChip('Paid', provider.paidChallans.length, color: AppColors.paidGreen),
                    const SizedBox(width: 10),
                    _filterChip('Pending', provider.pendingChallans.length, color: AppColors.pendingAmber),
                    const SizedBox(width: 10),
                    _filterChip('Overdue', provider.overdueChallans.length, color: AppColors.overdueCrimson),
                  ],
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.mintEmerald))
                      : displayList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_rounded, size: 70, color: context.textGreyColor.withValues(alpha: 0.3)),
                                  const SizedBox(height: 16),
                                  Text('No challans found',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textDarkColor)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => provider.fetchChallans(),
                              child: ListView.separated(
                                itemCount: displayList.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final challan = displayList[index];
                                  return _ChallanCard(
                                    challan: challan,
                                    onMarkPaid: () => _openMarkPaidDialog(challan),
                                    onViewPdf: () => _downloadPdf(
                                        () => ApiService.downloadChallanPdf(challan.id)),
                                    onViewReceipt: () => _downloadPdf(
                                        () => ApiService.downloadReceiptPdf(challan.id)),
                                    onWhatsApp: () => _sendWhatsAppReminder(challan),
                                    onPayNow: () => _openPaymentOptions(challan),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, int count, {Color? color}) {
    final isActive = _activeFilter == label;
    final chipColor = color ?? AppColors.deepNavy;

    return Builder(
      builder: (context) {
        return InkWell(
          onTap: () => setState(() => _activeFilter = label),
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? chipColor : context.cardWhite,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: isActive ? chipColor : context.borderColor),
              boxShadow: isActive
                  ? [BoxShadow(color: chipColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Text(
              '$label ($count)',
              style: TextStyle(
                color: isActive ? Colors.white : context.textDarkColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===== Challan Card Widget =====
class _ChallanCard extends StatelessWidget {
  final FeeChallanModel challan;
  final VoidCallback onMarkPaid;
  final VoidCallback onViewPdf;
  final VoidCallback onViewReceipt;
  final VoidCallback onWhatsApp;
  final VoidCallback onPayNow;

  const _ChallanCard({
    required this.challan,
    required this.onMarkPaid,
    required this.onViewPdf,
    required this.onViewReceipt,
    required this.onWhatsApp,
    required this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(challan.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_rounded, color: statusColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challan.studentName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textDarkColor)),
                    const SizedBox(height: 2),
                    Text(
                      '${challan.challanNumber} • ${challan.studentRoll}',
                      style: TextStyle(fontSize: 12, color: context.textGreyColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  challan.status,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 14),
          Row(
            children: [
              _infoBit(context, 'Month', '${challan.month}/${challan.year}'),
              _infoBit(context, 'Due Date', '${challan.dueDate.day}/${challan.dueDate.month}/${challan.dueDate.year}'),
              _infoBit(context, 'Discount', '${challan.discountPercentage.toInt()}%'),
              _infoBit(context, 'Total', 'Rs. ${challan.totalPayable.toStringAsFixed(0)}', isBold: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (challan.status != 'Paid')
                Expanded(
                  child: RoleGuard(
                    allowedRoles: const ['admin'],
                    fallback: const SizedBox.shrink(),
                    child: _actionButton(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Mark as Paid',
                      color: AppColors.mintEmerald,
                      onTap: onMarkPaid,
                      isFilled: true,
                    ),
                  ),
                ),
              if (challan.status != 'Paid') const SizedBox(width: 10),
              Expanded(
                child: RoleGuard(
                  allowedRoles: const ['admin', 'parent'],
                  child: _actionButton(
                    icon: challan.status == 'Paid' ? Icons.description_rounded : Icons.picture_as_pdf_rounded,
                    label: challan.status == 'Paid' ? 'Receipt' : 'Challan PDF',
                    color: AppColors.deepNavy,
                    onTap: challan.status == 'Paid' ? onViewReceipt : onViewPdf,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RoleGuard(
                  allowedRoles: const ['admin'],
                  fallback: const SizedBox.shrink(),
                  child: _actionButton(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: onWhatsApp,
                    isFilled: true,
                  ),
                ),
              ),
            ],
          ),
          if (challan.status != 'Paid') ...[
            const SizedBox(height: 10),
            RoleGuard(
              allowedRoles: const ['admin', 'parent'],
              fallback: const SizedBox.shrink(),
              child: SizedBox(
                width: double.infinity,
                child: _actionButton(
                  icon: Icons.payment_rounded,
                  label: 'Pay Now',
                  color: const Color(0xFF2ECC9A),
                  onTap: onPayNow,
                  isFilled: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoBit(BuildContext context, String label, String value, {bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: context.textGreyColor)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: context.textDarkColor)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFilled = false,
  }) {
    return Material(
      color: isFilled ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isFilled ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isFilled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}