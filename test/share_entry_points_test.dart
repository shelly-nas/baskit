import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/repositories/auth_repository.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/frontend/presentation/screens/list_detail_screen.dart';
import 'package:baskit/frontend/presentation/screens/lists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_baskit_server.dart';
import 'support/fake_offer_repository.dart';

/// Sharing must be easy to find: a button on an open list and an entry in
/// the list's menu on the Lists tab, for the owner.
void main() {
  late FakeBaskitServer server;
  late AppDependencies app;
  late String listId;

  // In each test, not in setUp: async work there runs outside the widget
  // test's zone and its futures would never complete inside the test.
  Future<void> signIn() async {
    server = FakeBaskitServer()..addUser('jelle@example.com', 'Jelle');
    final store = InMemoryStore()
      ..values[AuthRepository.tokenKey] = 'token-jelle@example.com';
    app = AppDependencies.create(
      store: store,
      baskitApi: server.client(),
      offerRepository: FakeOfferRepository(),
    );
    await app.authController.restore();
    listId = (await app.shoppingListController.createList('Weekend'))!.id;
  }

  testWidgets('an open list has a share button', (tester) async {
    await signIn();
    await tester.pumpWidget(
      MaterialApp(
        home: ListDetailScreen(
          controller: app.shoppingListController,
          listId: listId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Share list'));
    await tester.pumpAndSettle();

    expect(find.text('Share "Weekend"'), findsOneWidget);
  });

  testWidgets('the Lists tab offers Share in the list menu', (tester) async {
    await signIn();
    await tester.pumpWidget(
      MaterialApp(home: ListsScreen(controller: app.shoppingListController)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('List options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(find.text('Share "Weekend"'), findsOneWidget);
  });

  testWidgets('a list someone shared with you has no share button', (
    tester,
  ) async {
    await signIn();
    server.lists[listId]!['role'] = 'editor';
    server.lists[listId]!['owner'] = {'id': 'user-9', 'display_name': 'Anna'};
    await app.shoppingListController.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: ListDetailScreen(
          controller: app.shoppingListController,
          listId: listId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Share list'), findsNothing);
    expect(find.text('Shared by Anna'), findsOneWidget);
  });
}
