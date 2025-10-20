// lib/screens/pos/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:pos_app/database/database_helper.dart';
import 'package:pos_app/screens/pos/receipt_screen.dart';

class PaymentScreen extends StatelessWidget {
  final Map<int, int> cart;
  final int totalAmount;

  const PaymentScreen(
      {super.key, required this.cart, required this.totalAmount});

  void _processPayment(BuildContext context) async {
    // 1. Simpan transaksi ke database dan dapatkan ID-nya
    final newTransactionId =
        await DatabaseHelper.instance.createTransaction(cart, totalAmount);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Pembayaran Berhasil!'), backgroundColor: Colors.green),
    );

    // 2. Arahkan ke halaman Struk dan hapus semua halaman sebelumnya sampai ke Home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(transactionId: newTransactionId),
      ),
      (Route<dynamic> route) =>
          route.isFirst, // Hapus semua route sampai ke root (HomeScreen)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Total yang Harus Dibayar:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                'Rp. $totalAmount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => _processPayment(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Selesaikan Pembayaran',
                    style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
