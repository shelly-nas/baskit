import 'dart:async';

import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/data_sources/remote_shopping_list_data_source.dart';
import 'package:baskit/database/repositories/auth_repository.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/frontend/presentation/controllers/shopping_list_controller.dart';
import 'package:baskit/frontend/presentation/screens/list_detail_screen.dart';
import 'package:baskit/frontend/presentation/screens/lists_screen.dart';
import 'package:baskit/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_baskit_server.dart';
import 'support/fake_offer_repository.dart';

/// Two controllers on one server stand in for two devices of a household:
/// what one saves, the other only sees after it fetches the lists again.
void main() {
  late FakeBaskitServer server;
  late ShoppingListController mine;
  late ShoppingListController theirs;

  ShoppingListController device() {
    final api = server.client()..token = 'token-jelle@example.com';
    final remote = RemoteShoppingListDataSource(api);
    return ShoppingListController(
      buildShoppingListService(remote),
      remote: remote,
    );
  }

  setUp(() {
    server = FakeBaskitServer()..addUser('jelle@example.com', 'Jelle');
    mine = device();
    theirs = device();
  });

  test('refresh picks up a change made on another device', () async {
    await mine.load();
    final list = await theirs.createList('Weekend');
    await theirs.addItem(list!.id, 'Coffee');
    expect(mine.lists, isEmpty);

    await mine.refresh();

    expect(mine.lists.single.name, 'Weekend');
    expect(mine.lists.single.items.single.name, 'Coffee');
  });

  test('a failed refresh keeps the lists and shows no message', () async {
    await mine.load();
    await mine.createList('Weekend');

    server.offline = true;
    await mine.refresh();

    expect(mine.lists.single.name, 'Weekend');
    expect(mine.error, isNull);
    expect(mine.messages.value, isNull);
  });

  test('a refresh does not undo a change saved while it ran', () async {
    await mine.load();
    final list = await mine.createList('Weekend');

    // The refresh reads the lists before the item is added ...
    final hold = server.holdNextListsRead = Completer<void>();
    final refreshing = mine.refresh();
    await pumpEventQueue();
    await mine.addItem(list!.id, 'Coffee');
    // ... and its answer arrives after the change was saved.
    hold.complete();
    await refreshing;

    expect(mine.lists.single.items.single.name, 'Coffee');
  });

  testWidgets('auto refresh fetches the lists every interval until stopped', (
    tester,
  ) async {
    await mine.load();

    mine.startAutoRefresh(const Duration(seconds: 10));
    await theirs.createList('Weekend');
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    expect(mine.lists.single.name, 'Weekend');

    mine.stopAutoRefresh();
    await theirs.createList('Party');
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(mine.lists, hasLength(1));
  });

  testWidgets('pull down on the Lists tab to refresh', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ListsScreen(controller: mine)));
    await tester.pumpAndSettle();
    await theirs.createList('Weekend');
    expect(find.text('Weekend'), findsNothing);

    await tester.fling(find.text('No lists yet'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Weekend'), findsOneWidget);
  });

  testWidgets('pull down on an open list to see what others added', (
    tester,
  ) async {
    await mine.load();
    final list = await mine.createList('Weekend');
    await tester.pumpWidget(
      MaterialApp(
        home: ListDetailScreen(controller: mine, listId: list!.id),
      ),
    );
    await tester.pumpAndSettle();
    await theirs.load();
    await theirs.addItem(list.id, 'Coffee');
    expect(find.text('Coffee'), findsNothing);

    await tester.fling(find.text('Add an item'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets(
    'signed in, the app refreshes while it is open and not in the background',
    (tester) async {
      final store = InMemoryStore()
        ..values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      final app = AppDependencies.create(
        store: store,
        baskitApi: server.client(),
        offerRepository: FakeOfferRepository(),
      );
      await app.authController.restore();
      await tester.pumpWidget(BaskitApp(dependencies: app));
      await tester.pumpAndSettle();
      final lists = app.shoppingListController;

      await theirs.createList('Weekend');
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      expect(lists.lists.single.name, 'Weekend');

      // In the background: no requests.
      moveTo(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden]);
      await theirs.createList('Party');
      await tester.pump(const Duration(seconds: 30));
      await tester.pump();
      expect(lists.lists, hasLength(1));

      // Back in front: fetched at once.
      moveTo(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
      await tester.pump();
      await tester.pump();
      expect(lists.lists, hasLength(2));

      // Signed out: the timer stops with the main screen.
      await app.authController.signOut();
      await tester.pumpAndSettle();
      final requests = server.requests.length;
      await tester.pump(const Duration(seconds: 30));
      expect(server.requests.length, requests);
    },
  );
}

/// Goes through lifecycle states one by one, as a real app does.
void moveTo(WidgetTester tester, List<AppLifecycleState> states) {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}
