import 'package:baskit/backend/models/offer.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_shopping_lists.dart';

void main() {
  test('lists, items and offers survive a restart', () async {
    final store = InMemoryStore();
    final first = createShoppingListController(store);
    await first.load();

    final list = (await first.createList('  Weekly groceries '))!;
    await first.addItem(list.id, 'Bread', quantity: '2');
    await first.addOffer(
      list.id,
      Offer(
        productId: 7,
        name: 'Halfvolle melk 1L',
        category: 'Zuivel',
        supermarket: const Supermarket(key: 'dirk', name: 'Dirk'),
        originalPrice: 1.09,
        discountPrice: 0.79,
        specialDiscount: '2 voor 1,50',
        expireDate: DateTime.utc(2030, 1, 1),
      ),
    );
    final bread = first.listById(list.id)!.items.first;
    await first.toggleItem(list.id, bread);

    // A new controller over the same store sees everything.
    final second = createShoppingListController(store);
    await second.load();
    final restored = second.listById(list.id)!;

    expect(restored.name, 'Weekly groceries');
    expect(restored.itemCount, 2);
    expect(restored.completedItemsCount, 1);
    expect(restored.items.first.quantity, '2');

    final milk = restored.items.last;
    expect(milk.offer, isNotNull);
    expect(milk.offer!.supermarketKey, 'dirk');
    expect(milk.offer!.price, 0.79);
    expect(milk.offer!.specialDiscount, '2 voor 1,50');
    expect(milk.offer!.expireDate, DateTime.utc(2030, 1, 1));
    expect(restored.offerTotal, closeTo(0.79, 0.001));
  });

  test('deleting items and lists is persisted', () async {
    final store = InMemoryStore();
    final controller = createShoppingListController(store);
    await controller.load();

    final keep = (await controller.createList('Keep'))!;
    final remove = (await controller.createList('Remove'))!;
    await controller.addItem(keep.id, 'Apples');
    await controller.addItem(keep.id, 'Pears');
    final apples = controller.listById(keep.id)!.items.first;
    await controller.toggleItem(keep.id, apples);
    await controller.clearCompleted(keep.id);
    await controller.deleteList(remove.id);

    final reloaded = createShoppingListController(store);
    await reloaded.load();
    expect(reloaded.lists.map((l) => l.name), ['Keep']);
    expect(reloaded.lists.single.items.map((i) => i.name), ['Pears']);
  });

  test('empty names are rejected with a message', () async {
    final controller = createShoppingListController();
    await controller.load();
    expect(await controller.createList('   '), isNull);
    expect(controller.messages.value, 'List name cannot be empty');
    expect(controller.lists, isEmpty);
  });
}
