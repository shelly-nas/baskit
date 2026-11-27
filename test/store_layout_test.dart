import 'package:baskit/backend/models/shopping_list.dart';
import 'package:baskit/backend/services/store_layout.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/frontend/presentation/controllers/shopping_list_controller.dart';
import 'package:baskit/frontend/presentation/screens/list_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_shopping_lists.dart';

ListItem item(String name, {String? category}) => ListItem(
  id: name,
  name: name,
  category: category,
  isCompleted: false,
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  test('the supermarket category decides the section', () {
    expect(
      StoreLayout.sectionOf(item('X', category: 'Groente, aardappelen')),
      StoreSection.produce,
    );
    expect(
      StoreLayout.sectionOf(item('X', category: 'Zuivel, eieren')),
      StoreSection.dairy,
    );
    expect(
      StoreLayout.sectionOf(item('X', category: 'Diepvries')),
      StoreSection.frozen,
    );
  });

  test('without a category the name decides', () {
    expect(StoreLayout.sectionOf(item('Bananen')), StoreSection.produce);
    expect(StoreLayout.sectionOf(item('Halfvolle melk')), StoreSection.dairy);
    expect(StoreLayout.sectionOf(item('Kipfilet')), StoreSection.meatAndFish);
    expect(StoreLayout.sectionOf(item('Volkoren brood')), StoreSection.bakery);
    expect(StoreLayout.sectionOf(item('Wc-papier')), StoreSection.household);
  });

  test('the most specific word wins', () {
    // "melk" is dairy, but "melkchocolade" is sweets.
    expect(StoreLayout.sectionOf(item('Melkchocolade')), StoreSection.sweets);
    // "kaas" is cheese, "kaasstengels" are snacks.
    expect(StoreLayout.sectionOf(item('Kaasstengels')), StoreSection.sweets);
  });

  test('unknown items go last', () {
    expect(StoreLayout.sectionOf(item('Batterijen')), StoreSection.other);
  });

  test('items are grouped in the order of a walk through the shop', () {
    final groups = StoreLayout.group([
      item('Wc-papier'),
      item('Melk'),
      item('Appels'),
      item('Batterijen'),
      item('Yoghurt'),
    ]);

    expect(groups.map((g) => g.section), [
      StoreSection.produce,
      StoreSection.dairy,
      StoreSection.household,
      StoreSection.other,
    ]);
    // Within a section the order of the list stays.
    expect(groups[1].items.map((i) => i.name), ['Melk', 'Yoghurt']);
  });

  group('list screen', () {
    late InMemoryStore store;
    late ShoppingListController lists;

    ShoppingListController controller() => ShoppingListController(
      createShoppingListService(store),
      preferences: store,
    );

    Future<String> openList(WidgetTester tester, List<String> items) async {
      store = InMemoryStore();
      lists = controller();
      await lists.load();
      final list = await lists.createList('Weekend');
      for (final name in items) {
        await lists.addItem(list!.id, name);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: ListDetailScreen(controller: lists, listId: list!.id),
        ),
      );
      await tester.pumpAndSettle();
      return list.id;
    }

    double top(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    testWidgets('open items are grouped in the order of the shop', (
      tester,
    ) async {
      await openList(tester, ['Wc-papier', 'Melk', 'Appels']);

      expect(find.text('Vegetables and fruit'), findsOneWidget);
      expect(find.text('Dairy and eggs'), findsOneWidget);
      expect(find.text('Household'), findsOneWidget);
      expect(top(tester, 'Appels'), lessThan(top(tester, 'Melk')));
      expect(top(tester, 'Melk'), lessThan(top(tester, 'Wc-papier')));
    });

    testWidgets('sort as added instead, remembered on this device', (
      tester,
    ) async {
      await openList(tester, ['Wc-papier', 'Melk', 'Appels']);

      await tester.tap(find.byTooltip('List options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort as added'));
      await tester.pumpAndSettle();

      expect(find.text('Household'), findsNothing);
      expect(top(tester, 'Wc-papier'), lessThan(top(tester, 'Appels')));

      final next = controller();
      await next.load();
      expect(next.sortByLayout, isFalse);
    });

    testWidgets('checking off can be undone', (tester) async {
      final listId = await openList(tester, ['Melk']);

      await tester.tap(find.bySemanticsLabel('Mark as done'));
      await tester.pumpAndSettle();
      expect(find.text('Checked off Melk'), findsOneWidget);
      expect(lists.listById(listId)!.items.single.isCompleted, isTrue);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(lists.listById(listId)!.items.single.isCompleted, isFalse);
    });
  });
}
