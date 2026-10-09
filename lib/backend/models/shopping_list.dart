/// Shopping List Domain Model
/// Business logic model with computed properties and business rules
class ShoppingList {
  final String id;
  final String name;
  final String? description;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ListItem> items;

  ShoppingList({
    required this.id,
    required this.name,
    this.description,
    required this.isShared,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  /// Get the total number of items
  int get itemCount => items.length;

  /// Get the number of completed items
  int get completedItemsCount => items.where((item) => item.isCompleted).length;

  /// Get the completion percentage (0.0 to 1.0)
  double get completionPercentage {
    if (items.isEmpty) return 0.0;
    return completedItemsCount / items.length;
  }

  /// Check if the list is completed (all items checked)
  bool get isCompleted =>
      items.isNotEmpty && completedItemsCount == items.length;

  /// Check if the list is empty
  bool get isEmpty => items.isEmpty;

  /// Get items grouped by category
  Map<String, List<ListItem>> get itemsByCategory {
    final Map<String, List<ListItem>> grouped = {};
    for (final item in items) {
      final category = item.category ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }
    return grouped;
  }

  /// Items that are linked to a supermarket offer
  List<ListItem> get offerItems =>
      items.where((item) => item.offer != null).toList();

  /// Sum of the offer prices of all items that are linked to an offer
  double get offerTotal =>
      offerItems.fold(0.0, (sum, item) => sum + item.offer!.price);

  /// Get uncompleted items
  List<ListItem> get uncompletedItems =>
      items.where((item) => !item.isCompleted).toList();

  /// Get completed items
  List<ListItem> get completedItems =>
      items.where((item) => item.isCompleted).toList();

  /// Create a copy with updated fields
  ShoppingList copyWith({
    String? id,
    String? name,
    String? description,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ListItem>? items,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

/// List Item Domain Model
/// Business logic model for individual shopping list items
class ListItem {
  final String id;
  final String name;
  final String? quantity;
  final String? category;
  final bool isCompleted;
  final DateTime createdAt;

  /// The supermarket offer this item was added from, if any.
  final ListItemOffer? offer;

  ListItem({
    required this.id,
    required this.name,
    this.quantity,
    this.category,
    this.isCompleted = false,
    required this.createdAt,
    this.offer,
  });

  /// Create a copy with updated fields
  ListItem copyWith({
    String? id,
    String? name,
    String? quantity,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
    ListItemOffer? offer,
    bool clearOffer = false,
  }) {
    return ListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      offer: clearOffer ? null : (offer ?? this.offer),
    );
  }

  /// Toggle completion status
  ListItem toggleCompleted() {
    return copyWith(isCompleted: !isCompleted);
  }
}

/// Snapshot of a supermarket offer stored on a list item, so the list still
/// shows where and for how much an item was on offer when the offer is gone.
class ListItemOffer {
  final int productId;
  final String supermarketKey;
  final String supermarketName;
  final double price;
  final double? originalPrice;
  final String? specialDiscount;
  final DateTime expireDate;

  const ListItemOffer({
    required this.productId,
    required this.supermarketKey,
    required this.supermarketName,
    required this.price,
    this.originalPrice,
    this.specialDiscount,
    required this.expireDate,
  });

  bool isExpired([DateTime? now]) => expireDate.isBefore(now ?? DateTime.now());
}
