/// Shopping List Entity
/// Database entity representing a shopping list
class ShoppingListEntity {
  final String id;
  final String name;
  final String? description;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ListItemEntity> items;

  /// Server lists only: 'owner' or 'editor' for the signed-in user.
  final String? role;

  /// Server lists only: {id, display_name, email}.
  final Map<String, dynamic>? owner;

  /// Server lists only: people the list is shared with.
  final List<Map<String, dynamic>> members;

  ShoppingListEntity({
    required this.id,
    required this.name,
    this.description,
    required this.isShared,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.role,
    this.owner,
    this.members = const [],
  });

  /// Convert from JSON (e.g., from API or local database)
  factory ShoppingListEntity.fromJson(Map<String, dynamic> json) {
    return ShoppingListEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isShared: json['is_shared'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => ListItemEntity.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      role: json['role'] as String?,
      owner: json['owner'] as Map<String, dynamic>?,
      members:
          (json['members'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>()
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON (e.g., for API or local database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_shared': isShared,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      if (role != null) 'role': role,
      if (owner != null) 'owner': owner,
      if (members.isNotEmpty) 'members': members,
    };
  }

  /// Create a copy with updated fields
  ShoppingListEntity copyWith({
    String? id,
    String? name,
    String? description,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ListItemEntity>? items,
  }) {
    return ShoppingListEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      role: role,
      owner: owner,
      members: members,
    );
  }
}

/// List Item Entity
/// Database entity representing an item in a shopping list
class ListItemEntity {
  final String id;
  final String name;
  final String? quantity;
  final String? category;
  final bool isCompleted;
  final DateTime createdAt;

  /// Offer snapshot as stored JSON (see ListItemOffer); null for plain items.
  final Map<String, dynamic>? offer;

  ListItemEntity({
    required this.id,
    required this.name,
    this.quantity,
    this.category,
    this.isCompleted = false,
    required this.createdAt,
    this.offer,
  });

  /// Convert from JSON
  factory ListItemEntity.fromJson(Map<String, dynamic> json) {
    return ListItemEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String?,
      category: json['category'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      offer: json['offer'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'offer': offer,
    };
  }

  /// Create a copy with updated fields
  ListItemEntity copyWith({
    String? id,
    String? name,
    String? quantity,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
    Map<String, dynamic>? offer,
  }) {
    return ListItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      offer: offer ?? this.offer,
    );
  }
}
