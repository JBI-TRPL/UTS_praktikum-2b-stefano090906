import 'package:flutter/material.dart';
import 'package:pos_app/models/user_model.dart';
import 'package:pos_app/screens/auth/login_screen.dart';
import 'package:pos_app/screens/pos/pos_screen.dart';
import 'package:pos_app/screens/product/product_management_screen.dart';
import 'package:pos_app/screens/transaction/transaction_history_screen.dart';
import 'package:pos_app/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // currentUser initialized in initState

    final List<Widget> pages = [
      _dashboard(context),
      const TransactionHistoryScreen(),
      ProfileScreen(user: _currentUser),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.blue.shade50,
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.history), label: 'Transactions'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _dashboard(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${_currentUser.fullname}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
            _buildDashboardCard(
            context,
            icon: Icons.point_of_sale,
            label: 'Transaksi Baru',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const PosScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.inventory,
            label: 'Manajemen Produk',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProductManagementScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.history,
            label: 'Riwayat Transaksi',
            onTap: () {
              setState(() => _selectedIndex = 1);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openProfile() async {
    final updated = await Navigator.push<User?>(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(user: _currentUser)),
    );
    if (updated != null) {
      setState(() {
        _currentUser = updated;
      });
    }
  }

  Widget _buildDashboardCard(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
