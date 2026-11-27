import 'package:baskit/backend/services/item_suggestion_service.dart';
import 'package:baskit/backend/services/offer_search_service.dart';
import 'package:baskit/database/data_sources/item_suggestion_data_source.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/data_sources/offline_shopping_list_data_source.dart';
import 'package:baskit/database/data_sources/remote_shopping_list_data_source.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/frontend/presentation/controllers/shopping_list_controller.dart';
import 'package:baskit/frontend/presentation/screens/list_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_baskit_server.dart';
import 'support/fake_offer_repository.dart';

void main() {
  late FakeBaskitServer server;
  late ShoppingListController lists;
  late ItemSuggestionService suggestions;

  setUp(() {
    server = FakeBaskitServer()..addUser('jelle@example.com', 'Jelle');
    final api = server.client()..token = 'token-jelle@example.com';
    final remote = RemoteShoppingListDataSource(api);
    final offline = OfflineShoppingListDataSource(remote, InMemoryStore());
    lists = ShoppingListController(
      buildShoppingListService(offline),
      remote: remote,
      offline: offline,
    );
    suggestions = ItemSuggestionService(
      history: ItemSuggestionDataSource(api),
      offers: OfferSearchService(FakeOfferRepository()),
    );
  });

  group('service', () {
    test('suggests items added before, most added first', () async {
      await lists.load();
      final list = await lists.createList('Weekend');
      await lists.addItem(list!.id, 'Melk');
      await lists.addItem(list.id, 'Halfvolle melk');
      await lists.addItem(list.id, 'Melk');

      final result = await suggestions.suggest('mel', known: lists.lists);

      expect(result.names, ['Melk', 'Halfvolle melk']);
    });

    test('leaves out what is still open on the list', () async {
      await lists.load();
      final list = await lists.createList('Weekend');
      await lists.addItem(list!.id, 'Melk');
      final weekend = lists.listById(list.id)!;

      final result = await suggestions.suggest(
        'mel',
        known: lists.lists,
        openOn: weekend,
      );

      expect(result.names, isEmpty);
    });

    test('includes current offers that match', () async {
      await lists.load();
      final result = await suggestions.suggest('melk', known: lists.lists);

      expect(result.offers.map((o) => o.name), contains('Halfvolle melk 1L'));
      expect(result.offers.length, lessThanOrEqualTo(3));
    });

    test('offline, the names on the lists are suggested', () async {
      await lists.load();
      final list = await lists.createList('Weekend');
      await lists.addItem(list!.id, 'Koffie');

      server.offline = true;
      final result = await suggestions.suggest('kof', known: lists.lists);

      expect(result.names, ['Koffie']);
    });
  });

  group('list screen', () {
    Future<String> openList(WidgetTester tester) async {
      await lists.load();
      final list = await lists.createList('Weekend');
      await tester.pumpWidget(
        MaterialApp(
          home: ListDetailScreen(
            controller: lists,
            listId: list!.id,
            suggestions: suggestions,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return list.id;
    }

    testWidgets('tap a suggestion to add it', (tester) async {
      final listId = await openList(tester);
      await lists.addItem(listId, 'Koffie');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Mark as done'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'kof');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Koffie'));
      await tester.pumpAndSettle();

      final items = lists.listById(listId)!.items;
      expect(
        items.where((i) => i.name == 'Koffie' && !i.isCompleted),
        hasLength(1),
      );
      expect(find.widgetWithText(ListTile, 'Koffie'), findsNothing);
    });

    testWidgets('tap an offer to add it with its price', (tester) async {
      final listId = await openList(tester);

      await tester.enterText(find.byType(TextField), 'melk');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Halfvolle melk 1L'));
      await tester.pumpAndSettle();

      final item = lists.listById(listId)!.items.single;
      expect(item.name, 'Halfvolle melk 1L');
      expect(item.offer?.supermarketName, 'Dirk');
    });
  });
}
