import 'package:baskit/database/data_sources/baskit_api_client.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/data_sources/offline_shopping_list_data_source.dart';
import 'package:baskit/database/data_sources/remote_shopping_list_data_source.dart';
import 'package:baskit/database/models/shopping_list_entity.dart';
import 'package:baskit/database/repositories/auth_repository.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_baskit_server.dart';
import 'support/fake_offer_repository.dart';

void main() {
  late FakeBaskitServer server;
  late InMemoryStore store;
  late List<String> rejected;

  /// A fresh data source on the same device storage, like the app after a
  /// restart.
  OfflineShoppingListDataSource device() {
    final api = server.client()..token = 'token-jelle@example.com';
    return OfflineShoppingListDataSource(
      RemoteShoppingListDataSource(api),
      store,
      onRejected: rejected.add,
    );
  }

  ShoppingListEntity newList(String id, String name) {
    final now = DateTime.utc(2026, 11, 1);
    return ShoppingListEntity(
      id: id,
      name: name,
      isShared: false,
      createdAt: now,
      updatedAt: now,
      items: const [],
      role: 'owner',
    );
  }

  ListItemEntity newItem(String id, String name) => ListItemEntity(
    id: id,
    name: name,
    isCompleted: false,
    createdAt: DateTime.utc(2026, 11, 1),
  );

  List<String> serverItems(String listId) => [
    for (final item in server.lists[listId]!['items'] as List) item['name'],
  ];

  setUp(() {
    server = FakeBaskitServer()..addUser('jelle@example.com', 'Jelle');
    store = InMemoryStore();
    rejected = [];
  });

  test('lists loaded once are there without a connection', () async {
    final online = device();
    await online.createList(newList('l1', 'Weekend'));
    await online.addItem('l1', newItem('i1', 'Coffee'));
    await online.getAllLists();

    server.offline = true;
    final offline = device();
    final lists = await offline.getAllLists();

    expect(lists.single.name, 'Weekend');
    expect(lists.single.items.single.name, 'Coffee');
    expect(offline.status.value.isOffline, isTrue);
  });

  test('changes made offline show at once and sync in order later', () async {
    final source = device();
    await source.createList(newList('l1', 'Weekend'));
    await source.getAllLists();

    server.offline = true;
    await source.addItem('l1', newItem('i1', 'Coffee'));
    await source.addItem('l1', newItem('i2', 'Bread'));
    await source.updateItem(
      'l1',
      newItem('i1', 'Coffee').copyWith(isCompleted: true),
    );
    await source.deleteItem('l1', 'i2');
    await source.createList(newList('l2', 'Party'));

    final local = await source.getAllLists();
    expect(local.map((l) => l.name), containsAll(['Weekend', 'Party']));
    final weekend = local.firstWhere((l) => l.id == 'l1');
    expect(weekend.items.single.isCompleted, isTrue);
    expect(source.status.value.pending, 5);
    expect(serverItems('l1'), isEmpty);

    server.offline = false;
    final synced = await source.getAllLists();

    expect(serverItems('l1'), ['Coffee']);
    expect(server.lists['l1']!['items'][0]['is_completed'], isTrue);
    expect(server.lists.containsKey('l2'), isTrue);
    expect(synced, hasLength(2));
    expect(source.status.value.pending, 0);
    expect(source.status.value.isOffline, isFalse);
  });

  test('pending changes survive a restart of the app', () async {
    final before = device();
    await before.createList(newList('l1', 'Weekend'));
    await before.getAllLists();
    server.offline = true;
    await before.addItem('l1', newItem('i1', 'Coffee'));

    server.offline = false;
    await device().getAllLists();

    expect(serverItems('l1'), ['Coffee']);
  });

  test('a change the server refuses is dropped and reported', () async {
    final source = device();
    await source.createList(newList('l1', 'Weekend'));
    await source.createList(newList('l2', 'Party'));
    await source.getAllLists();

    server.offline = true;
    await source.addItem('l1', newItem('i1', 'Coffee'));
    await source.addItem('l2', newItem('i2', 'Chips'));
    // Meanwhile the owner deleted "Weekend".
    server.lists.remove('l1');

    server.offline = false;
    final lists = await source.getAllLists();

    expect(rejected, ['List not found']);
    expect(serverItems('l2'), ['Chips']);
    expect(lists.map((l) => l.name), ['Party']);
    expect(source.status.value.pending, 0);
  });

  test('online, a refused change is an error as before', () async {
    final source = device();
    await expectLater(
      source.addItem('missing', newItem('i1', 'Coffee')),
      throwsA(anything),
    );
    expect(source.status.value.pending, 0);
  });

  test('clear forgets the lists and pending changes (sign out)', () async {
    final source = device();
    await source.createList(newList('l1', 'Weekend'));
    await source.getAllLists();
    server.offline = true;
    await source.addItem('l1', newItem('i1', 'Coffee'));

    await source.clear();

    final next = device();
    expect(await next.getAllLists(), isEmpty);
    expect(next.status.value.pending, 0);
  });

  group('starting without a connection', () {
    AuthRepository auth() => AuthRepository(server.client(), store);

    test('a signed-in user stays signed in offline', () async {
      server.passwords['jelle@example.com'] = 'secret';
      await auth().signIn('jelle@example.com', 'secret');

      server.offline = true;
      final user = await auth().restore();

      expect(user?.displayName, 'Jelle');
    });

    test('the name changed last is the one used offline', () async {
      server.passwords['jelle@example.com'] = 'secret';
      final repository = auth();
      await repository.signIn('jelle@example.com', 'secret');
      server.users['jelle@example.com']!['display_name'] = 'Jelle V';
      await repository.restore();

      server.offline = true;
      expect((await auth().restore())?.displayName, 'Jelle V');
    });

    test('without an earlier sign-in on this device it still fails', () async {
      store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      server.offline = true;

      await expectLater(auth().restore(), throwsA(isA<BaskitApiException>()));
    });

    test('signing out forgets the user', () async {
      server.passwords['jelle@example.com'] = 'secret';
      final repository = auth();
      await repository.signIn('jelle@example.com', 'secret');
      await repository.signOut();

      server.offline = true;
      expect(await auth().restore(), isNull);
    });
  });

  testWidgets('the app works offline and says so until all is sent', (
    tester,
  ) async {
    store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
    final app = AppDependencies.create(
      store: store,
      baskitApi: server.client(),
      offerRepository: FakeOfferRepository(),
    );
    await app.authController.restore();
    final lists = app.shoppingListController;
    final list = await lists.createList('Weekend');
    await tester.pumpWidget(BaskitApp(dependencies: app));
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsNothing);

    server.offline = true;
    await lists.addItem(list!.id, 'Coffee');
    await tester.pump();

    expect(lists.lists.single.items.single.name, 'Coffee');
    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.textContaining('1 change waiting'), findsOneWidget);

    server.offline = false;
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(serverItems(list.id), ['Coffee']);
    expect(find.textContaining('Offline'), findsNothing);
  });

  testWidgets('a change refused on sync is shown as a message', (tester) async {
    store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
    final app = AppDependencies.create(
      store: store,
      baskitApi: server.client(),
      offerRepository: FakeOfferRepository(),
    );
    await app.authController.restore();
    final lists = app.shoppingListController;
    final list = await lists.createList('Weekend');
    await tester.pumpWidget(BaskitApp(dependencies: app));
    await tester.pumpAndSettle();

    server.offline = true;
    await lists.addItem(list!.id, 'Coffee');
    server.lists.remove(list.id);
    server.offline = false;
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.textContaining('not saved: List not found'), findsOneWidget);
  });

  test('signing out clears the lists kept on this device', () async {
    store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
    final app = AppDependencies.create(
      store: store,
      baskitApi: server.client(),
      offerRepository: FakeOfferRepository(),
    );
    await app.authController.restore();
    await app.shoppingListController.createList('Weekend');
    expect(store.values.keys, contains(OfflineShoppingListDataSource.cacheKey));

    await app.authController.signOut();

    expect(
      store.values.keys,
      isNot(contains(OfflineShoppingListDataSource.cacheKey)),
    );
  });
}
