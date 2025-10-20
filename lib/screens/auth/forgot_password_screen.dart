import 'package:flutter/material.dart';
import 'package:pos_app/database/database_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    if (username.isEmpty || email.isEmpty) return;

    final user = await DatabaseHelper.instance.getUserByUsername(username);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User tidak ditemukan')));
      return;
    }

    if (user.email != email) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email tidak cocok')));
      return;
    }

    // Ask user to enter new password
    final newPassword = await showDialog<String?> (
      context: context,
      builder: (context) {
        final pwController = TextEditingController();
        return AlertDialog(
          title: const Text('Set Password Baru'),
          content: TextField(
            controller: pwController,
            decoration: const InputDecoration(labelText: 'New Password'),
            obscureText: true,
          ),
          actions: [
            TextButton(onPressed: () { pwController.dispose(); Navigator.of(context).pop(null); }, child: const Text('Batal')),
            TextButton(onPressed: () { final val = pwController.text; pwController.dispose(); Navigator.of(context).pop(val); }, child: const Text('Simpan')),
          ],
        );
      },
    );

    if (newPassword == null || newPassword.isEmpty) return;
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter')));
      return;
    }

    final updated = user.copyWith(password: newPassword);
    await DatabaseHelper.instance.updateUser(updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _resetPassword, child: const Text('Reset Password'))
          ],
        ),
      ),
    );
  }
}
