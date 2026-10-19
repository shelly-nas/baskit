import '../../backend/models/shopping_list.dart';
import '../models/shopping_list_entity.dart';

/// Mapper for converting between ShoppingList entity and domain models
class ShoppingListMapper {
  /// Convert entity to domain model
  static ShoppingList toDomain(ShoppingListEntity entity) {
    return ShoppingList(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      isShared: entity.isShared,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      items: entity.items.map((item) => ListItemMapper.toDomain(item)).toList(),
      isOwner: entity.role != 'editor',
      owner: entity.owner == null ? null : _person(entity.owner!),
      members: entity.members.map(_person).toList(),
    );
  }

  static ListPerson _person(Map<String, dynamic> json) => ListPerson(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    email: json['email'] as String?,
  );

  /// Convert domain model to entity
  static ShoppingListEntity toEntity(ShoppingList domain) {
    return ShoppingListEntity(
      id: domain.id,
      name: domain.name,
      description: domain.description,
      isShared: domain.isShared,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      items: domain.items.map((item) => ListItemMapper.toEntity(item)).toList(),
    );
  }

  /// Convert list of entities to list of domain models
  static List<ShoppingList> toDomainList(List<ShoppingListEntity> entities) {
    return entities.map((entity) => toDomain(entity)).toList();
  }

  /// Convert list of domain models to list of entities
  static List<ShoppingListEntity> toEntityList(List<ShoppingList> domains) {
    return domains.map((domain) => toEntity(domain)).toList();
  }
}

/// Mapper for converting between ListItem entity and domain models
class ListItemMapper {
  /// Convert entity to domain model
  static ListItem toDomain(ListItemEntity entity) {
    return ListItem(
      id: entity.id,
      name: entity.name,
      quantity: entity.quantity,
      category: entity.category,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      offer: entity.offer == null ? null : offerFromJson(entity.offer!),
    );
  }

  /// Convert domain model to entity
  static ListItemEntity toEntity(ListItem domain) {
    return ListItemEntity(
      id: domain.id,
      name: domain.name,
      quantity: domain.quantity,
      category: domain.category,
      isCompleted: domain.isCompleted,
      createdAt: domain.createdAt,
      offer: domain.offer == null ? null : offerToJson(domain.offer!),
    );
  }

  static ListItemOffer offerFromJson(Map<String, dynamic> json) {
    return ListItemOffer(
      productId: (json['product_id'] as num).toInt(),
      supermarketKey: json['supermarket_key'] as String,
      supermarketName: json['supermarket_name'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      specialDiscount: json['special_discount'] as String?,
      expireDate: DateTime.parse(json['expire_date'] as String),
    );
  }

  static Map<String, dynamic> offerToJson(ListItemOffer offer) {
    return {
      'product_id': offer.productId,
      'supermarket_key': offer.supermarketKey,
      'supermarket_name': offer.supermarketName,
      'price': offer.price,
      'original_price': offer.originalPrice,
      'special_discount': offer.specialDiscount,
      'expire_date': offer.expireDate.toUtc().toIso8601String(),
    };
  }
}
