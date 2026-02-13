import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class FeePaymentScreen extends StatefulWidget {
  const FeePaymentScreen({super.key});

  @override
  State<FeePaymentScreen> createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends State<FeePaymentScreen> {
  List<dynamic> _list = [];
  bool _loading = true;
  final _amountController = TextEditingController();
  final _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMyFeePayments();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }
    try {
      await ApiService.createFeePayment(amount, academicYear: _yearController.text.trim().isEmpty ? null : _yearController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful')));
        _amountController.clear();
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Pay Fees', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount (₹)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),
                  TextField(controller: _yearController, decoration: const InputDecoration(labelText: 'Academic Year (optional)')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _pay, child: const Text('Pay')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('My Payments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? const EmptyStateMessage(message: 'No payments yet. Use the form above to pay fees.', icon: Icons.payment) : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _list.length,
            itemBuilder: (_, i) {
              final p = _list[i] as Map<String, dynamic>;
              final amount = (p['amount'] as num?)?.toDouble() ?? 0;
              final status = p['status'] as String? ?? '';
              final createdAt = p['createdAt'] != null ? DateTime.tryParse(p['createdAt'] as String) : null;
              return Card(
                child: ListTile(
                  title: Text('₹${amount.toStringAsFixed(2)}'),
                  subtitle: Text('$status${createdAt != null ? ' • ${DateFormat.yMd().format(createdAt)}' : ''}'),
                  trailing: Chip(label: Text(status), backgroundColor: status == 'Approved' ? Colors.green.shade100 : status == 'Rejected' ? Colors.red.shade100 : Colors.orange.shade100),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
