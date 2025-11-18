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
    );
  }

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
    );
  }
}
