import 'package:flutter/material.dart';
import 'package:pos_app/database/database_helper.dart';
import 'package:pos_app/models/product_model.dart';
import 'package:pos_app/screens/pos/cart_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  late Future<List<Product>> _productsFuture;
  Map<int, int> _cart = {}; // Key: productId, Value: quantity

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = DatabaseHelper.instance.getProducts();
    });
  }

  void _updateCart(int productId, int quantity) {
    setState(() {
      if (quantity > 0) {
        _cart[productId] = quantity;
      } else {
        _cart.remove(productId);
      }
    });
  }

  void _resetCart() {
    setState(() {
      _cart.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MENUS')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
                    'Tidak ada produk tersedia. Tambahkan produk terlebih dahulu.'));
          }

          final products = snapshot.data!;
          final makanan = products.where((p) => p.type == 'Makanan').toList();
          final minuman = products.where((p) => p.type == 'Minuman').toList();

          return CustomScrollView(
            slivers: [
              if (makanan.isNotEmpty) ...[
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Makanan",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)))),
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildProductItem(makanan[index]),
                        childCount: makanan.length)),
              ],
              if (minuman.isNotEmpty) ...[
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Minuman",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)))),
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildProductItem(minuman[index]),
                        childCount: minuman.length)),
              ],
              const SliverToBoxAdapter(
                  child: SizedBox(height: 100)), // Spacer for buttons
            ],
          );
        },
      ),
      bottomSheet: _buildActionButtons(),
    );
  }

  Widget _buildProductItem(Product product) {
    final quantity = _cart[product.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
                child: Text(quantity.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp. ${product.price}'),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (quantity > 0) {
                    _updateCart(product.id!, quantity - 1);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Colors.blue,
                onPressed: () {
                  _updateCart(product.id!, quantity + 1);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _cart.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CartScreen(cart: _cart)))
                          .then((transactionSuccess) {
                        // if transaction was successful, clear the cart
                        if (transactionSuccess == true) {
                          _resetCart();
                        }
                      });
                    },
              child: const Text('Transaction'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton(
              onPressed: _resetCart,
              child: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
