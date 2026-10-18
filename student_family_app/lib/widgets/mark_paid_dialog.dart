import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fee_provider.dart';
import '../models/fee_challan_model.dart';
import '../utils/app_theme.dart';

class MarkPaidDialog extends StatefulWidget {
  final FeeChallanModel challan;
  const MarkPaidDialog({super.key, required this.challan});

  @override
  State<MarkPaidDialog> createState() => _MarkPaidDialogState();
}

class _MarkPaidDialogState extends State<MarkPaidDialog> {
  late TextEditingController _amountCtrl;
  String _paymentMethod = 'Cash';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.challan.totalPayable.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppColors.overdueCrimson),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = Provider.of<FeeProvider>(context, listen: false);
    final success = await provider.markAsPaid(widget.challan.id, amount, _paymentMethod);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully! ✅'), backgroundColor: AppColors.mintEmerald),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage}'), backgroundColor: AppColors.overdueCrimson),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.mintGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payments_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Record Payment',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: context.textDarkColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Challan: ${widget.challan.challanNumber}',
              style: TextStyle(color: context.textGreyColor, fontSize: 13),
            ),
            const SizedBox(height: 22),

            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.textDarkColor),
              decoration: InputDecoration(
                labelText: 'Amount Received (Rs.)',
                labelStyle: TextStyle(color: context.textGreyColor),
                prefixIcon: Icon(Icons.attach_money_rounded, size: 20, color: context.textGreyColor),
                filled: true,
                fillColor: context.bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              dropdownColor: context.cardWhite,
              style: TextStyle(color: context.textDarkColor),
              decoration: InputDecoration(
                labelText: 'Payment Method',
                labelStyle: TextStyle(color: context.textGreyColor),
                prefixIcon: Icon(Icons.credit_card_rounded, size: 20, color: context.textGreyColor),
                filled: true,
                fillColor: context.bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'Card', child: Text('Card')),
                DropdownMenuItem(value: 'Online', child: Text('Online')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: context.textDarkColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirm Payment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}