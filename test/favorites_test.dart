import 'package:baskit/database/data_sources/favorites_data_source.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/repositories/auth_repository.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/frontend/presentation/controllers/favorites_controller.dart';
import 'package:baskit/frontend/presentation/screens/favorites_screen.dart';
import 'package:baskit/frontend/presentation/screens/list_detail_screen.dart';
import 'package:baskit/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_baskit_server.dart';
import 'support/fake_offer_repository.dart';

void main() {
  late FakeBaskitServer server;
  late InMemoryStore store;
  late List<String> messages;

  FavoritesController controller() {
    final api = server.client()..token = 'token-jelle@example.com';
    return FavoritesController(
      FavoritesDataSource(api, store),
      onMessage: messages.add,
    );
  }

  setUp(() {
    server = FakeBaskitServer()..addUser('jelle@example.com', 'Jelle');
    store = InMemoryStore();
    messages = [];
  });

  group('controller', () {
    test('add, find by name and remove favorites', () async {
      final favorites = controller();
      await favorites.load();
      await favorites.add('Melk', quantity: '2');
      await favorites.add('Brood');

      expect(favorites.favorites.map((f) => f.name), ['Brood', 'Melk']);
      expect(favorites.byName(' melk')?.quantity, '2');
      expect(server.favorites, hasLength(2));

      await favorites.remove(favorites.byName('Melk')!.id);
      expect(favorites.favorites.map((f) => f.name), ['Brood']);
      expect(server.favorites, hasLength(1));
    });

    test('the favorites are there without a connection', () async {
      await controller().add('Melk');

      server.offline = true;
      final offline = controller();
      await offline.load();

      expect(offline.favorites.single.name, 'Melk');
    });

    test('a change that cannot be saved is a message, not a crash', () async {
      final favorites = controller();
      await favorites.load();
      await favorites.add('Melk');
      await favorites.add('melk');
      expect(messages, ['Melk is already a favorite']);

      server.offline = true;
      await favorites.add('Brood');
      expect(messages.last, contains('Could not reach Baskit'));
      expect(favorites.favorites.map((f) => f.name), ['Melk']);
    });

    test('reset forgets the favorites on this device (sign out)', () async {
      final favorites = controller();
      await favorites.add('Melk');
      await favorites.reset();

      server.offline = true;
      final next = controller();
      await next.load();
      expect(next.favorites, isEmpty);
    });
  });

  group('screens', () {
    late AppDependencies app;

    Future<String> openList(WidgetTester tester, List<String> items) async {
      store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      app = AppDependencies.create(
        store: store,
        baskitApi: server.client(),
        offerRepository: FakeOfferRepository(),
      );
      await app.authController.restore();
      final list = await app.shoppingListController.createList('Weekend');
      for (final item in items) {
        await app.shoppingListController.addItem(list!.id, item);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: ListDetailScreen(
            controller: app.shoppingListController,
            listId: list!.id,
            favorites: app.favoritesController,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return list.id;
    }

    testWidgets('tap a favorite to put it on the list', (tester) async {
      final semantics = tester.ensureSemantics();
      server.favorites['f1'] = {'id': 'f1', 'name': 'Melk', 'quantity': '2'};
      server.favorites['f2'] = {'id': 'f2', 'name': 'Brood', 'quantity': null};
      final listId = await openList(tester, ['Brood']);

      // Brood is on the list already, so only Melk is offered; screen
      // readers get a button.
      expect(find.widgetWithText(ActionChip, 'Brood'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Add Melk')),
        isSemantics(label: 'Add Melk', isButton: true, hasTapAction: true),
      );
      await tester.tap(find.widgetWithText(ActionChip, 'Melk'));
      await tester.pumpAndSettle();

      final melk = app.shoppingListController
          .listById(listId)!
          .items
          .firstWhere((i) => i.name == 'Melk');
      expect(melk.quantity, '2');
      expect(find.widgetWithText(ActionChip, 'Melk'), findsNothing);
      semantics.dispose();
    });

    testWidgets('make an item on the list a favorite and undo it', (
      tester,
    ) async {
      await openList(tester, ['Koffie']);

      await tester.tap(find.text('Koffie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to favorites'));
      await tester.pumpAndSettle();
      expect(server.favorites.values.single['name'], 'Koffie');

      await tester.tap(find.text('Koffie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from favorites'));
      await tester.pumpAndSettle();
      expect(server.favorites, isEmpty);
    });

    testWidgets('the profile lists the favorites to manage them', (
      tester,
    ) async {
      store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      server.favorites['f1'] = {'id': 'f1', 'name': 'Melk', 'quantity': null};
      app = AppDependencies.create(
        store: store,
        baskitApi: server.client(),
        offerRepository: FakeOfferRepository(),
      );
      await app.authController.restore();
      await tester.pumpWidget(BaskitApp(dependencies: app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Eieren');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Melk from favorites'));
      await tester.pumpAndSettle();

      expect(server.favorites.values.map((f) => f['name']), ['Eieren']);
      expect(find.text('Eieren'), findsOneWidget);
      expect(find.text('Melk'), findsNothing);
    });
  });
}
