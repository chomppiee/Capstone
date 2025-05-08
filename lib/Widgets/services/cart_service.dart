class CartItem {
  final String id;
  final String name;
  final int cost;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.imageUrl,
    this.quantity = 1,
  });
}

class CartService {
  static final List<CartItem> items = [];

  static void addItem(CartItem item) {
    final index = items.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      items[index].quantity += 1; // already in bag → increment
    } else {
      items.add(item);           // new → add with qty=1
    }
  }

  static void clear() => items.clear();
}
