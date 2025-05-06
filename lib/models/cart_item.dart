import 'package:soloz/models/product.dart';

class CartItem {
  final String id;
  final Product product;
  final String selectedSize;
  final String selectedColor;
  final int quantity;

  CartItem({
    required this.id,
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    String? selectedSize,
    String? selectedColor,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      quantity: quantity ?? this.quantity,
    );
  }
} 