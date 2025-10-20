class Transaction {
  final int? id;
  final int totalAmount;
  final DateTime transactionDate;

  Transaction(
      {this.id, required this.totalAmount, required this.transactionDate});

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      totalAmount: map['totalAmount'],
      transactionDate: DateTime.parse(map['transactionDate']),
    );
  }
}

class TransactionDetail {
  final String productName;
  final int quantity;
  final int priceAtTransaction;

  TransactionDetail(
      {required this.productName,
      required this.quantity,
      required this.priceAtTransaction});

  factory TransactionDetail.fromMap(Map<String, dynamic> map) {
    return TransactionDetail(
      productName: map['name'],
      quantity: map['quantity'],
      priceAtTransaction: map['priceAtTransaction'],
    );
  }
}
