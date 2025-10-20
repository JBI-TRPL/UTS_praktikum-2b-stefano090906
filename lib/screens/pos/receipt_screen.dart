import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_app/database/database_helper.dart';
import 'package:pos_app/models/transaction_model.dart' as model;
import 'package:screenshot/screenshot.dart';
// path_provider removed; not used

class ReceiptScreen extends StatefulWidget {
  final int transactionId;
  const ReceiptScreen({super.key, required this.transactionId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;

  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadTransactionDetails();
  }

  Future<Map<String, dynamic>> _loadTransactionDetails() async {
    final transaction =
        await DatabaseHelper.instance.getTransactionById(widget.transactionId);
    final details = await DatabaseHelper.instance
        .getTransactionDetails(widget.transactionId);
    return {'transaction': transaction, 'details': details};
  }

  // Fungsi untuk memeriksa izin
  Future<bool> _checkAndRequestPermissions() async {
    var storageStatus = await Permission.storage.status;
    var mediaStatus = await Permission.mediaLibrary.status;
    var photosStatus = await Permission.photos.status;

    if (storageStatus.isPermanentlyDenied ||
        mediaStatus.isPermanentlyDenied ||
        photosStatus.isPermanentlyDenied) {
      if (!mounted) return false;
      final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Izin Diperlukan'),
              content: const Text(
                  'Untuk menyimpan struk ke galeri, aplikasi memerlukan izin penyimpanan. '
                  'Silakan buka pengaturan untuk memberikan izin yang diperlukan.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldOpenSettings) {
        await openAppSettings();
        // Periksa ulang izin setelah kembali dari settings
        return await _checkAndRequestPermissions();
      }
      return false;
    }

    if (storageStatus.isDenied ||
        mediaStatus.isDenied ||
        photosStatus.isDenied) {
      if (!mounted) return false;
      final shouldRequest = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Izin Diperlukan'),
              content: const Text(
                  'Aplikasi memerlukan izin untuk menyimpan struk ke galeri foto Anda. '
                  'Izin ini diperlukan agar struk dapat disimpan sebagai bukti transaksi.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Tidak'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('OK'),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldRequest) return false;

      final results = await Future.wait([
        Permission.storage.request(),
        Permission.mediaLibrary.request(),
        Permission.photos.request(),
      ]);

      return results.every((status) => status.isGranted);
    }

    return storageStatus.isGranted &&
        mediaStatus.isGranted &&
        photosStatus.isGranted;
  }

  // 2. Fungsi untuk download struk
  void _downloadReceipt() async {
    final hasPermission = await _checkAndRequestPermissions();
    if (!mounted) return;
    if (hasPermission) {
      try {
        final image = await _screenshotController.capture();

        if (image != null) {
          // Gunakan platform channel untuk menyimpan gambar ke galeri
          final methodChannel = const MethodChannel('pos_app/gallery');
          try {
            final result = await methodChannel.invokeMethod('saveImage', {
              'imageData': image,
              'name':
                  'Receipt_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
            });

            if (!mounted) return;
            if (result == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Struk berhasil disimpan di galeri!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal menyimpan struk.')),
              );
            }
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error menyimpan struk: ${e.toString()}')),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aplikasi memerlukan izin untuk menyimpan struk.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!['transaction'] == null) {
            return const Center(child: Text('Gagal memuat detail transaksi.'));
          }

          final model.Transaction transaction = snapshot.data!['transaction'];
          final List<model.TransactionDetail> details =
              snapshot.data!['details'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Receipt preview
                Screenshot(
                  controller: _screenshotController,
                  child: Card(
                    elevation: 2,
                    color: Colors
                        .white, // Pastikan ada background color agar tidak transparan
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                              child: Text('--- STRUK PEMBAYARAN ---',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(height: 20),
                          Text('No. Transaksi: #${transaction.id}'),
                          Text(
                              'Tanggal: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(transaction.transactionDate)}'),
                          const Divider(height: 30),
                          ...details.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child: Text(
                                                '${item.quantity}x ${item.productName}')),
                                        Text(
                                            'Rp. ${item.priceAtTransaction * item.quantity}'),
                                      ],
                                    ),
                                  )),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('Rp. ${transaction.totalAmount}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 30),
                          const Center(
                              child: Text('--- Terima Kasih ---',
                                  style: TextStyle(color: Colors.grey))),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // 4. Ubah tombol dan panggil fungsi download
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  onPressed: _downloadReceipt,
                  label: const Text('OK & Download Struk'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
