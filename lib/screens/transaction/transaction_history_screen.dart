import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/database/database_helper.dart';
import 'package:pos_app/models/transaction_model.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = DatabaseHelper.instance.getTransactions();
  }

  void _showTransactionDetails(Transaction transaction) async {
    final details =
        await DatabaseHelper.instance.getTransactionDetails(transaction.id!);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Transaksi #${transaction.id}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: details.length,
            itemBuilder: (context, index) {
              final detail = details[index];
              return ListTile(
                title: Text(detail.productName),
                subtitle: Text(
                    '${detail.quantity} x Rp. ${detail.priceAtTransaction}'),
                trailing:
                    Text('Rp. ${detail.quantity * detail.priceAtTransaction}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada riwayat transaksi.'));
          }
          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Transaksi #${transaction.id}'),
                  subtitle: Text(DateFormat('dd MMMM yyyy, HH:mm')
                      .format(transaction.transactionDate)),
                  trailing: Text('Rp. ${transaction.totalAmount}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => _showTransactionDetails(transaction),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
