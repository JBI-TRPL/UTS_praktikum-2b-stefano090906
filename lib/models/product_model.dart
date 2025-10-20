class Product {
  final int? id;
  final String name;
  final int price;
  final String type; // 'Makanan' atau 'Minuman'

  Product(
      {this.id, required this.name, required this.price, required this.type});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'type': type,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      type: map['type'],
    );
  }
}
