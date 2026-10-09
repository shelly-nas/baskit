import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/repositories/auth_repository.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/frontend/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_baskit_server.dart';
import 'support/fake_offer_repository.dart';

void main() {
  late FakeBaskitServer server;
  late InMemoryStore store;
  late AppDependencies deps;

  setUp(() {
    server = FakeBaskitServer()..addUser('jelle@example.com', 'Jelle');
    store = InMemoryStore();
    deps = AppDependencies.create(
      store: store,
      baskitApi: server.client(),
      offerRepository: FakeOfferRepository(),
    );
  });

  test('signing in moves device lists to the account', () async {
    final lists = deps.shoppingListController;
    await lists.load();
    final groceries = (await lists.createList('Groceries'))!;
    await lists.addItem(groceries.id, 'Melk');
    expect(lists.isSynced, isFalse);

    await deps.authController.signIn('jelle@example.com', 'correct horse');

    expect(deps.authController.user!.displayName, 'Jelle');
    expect(store.values[AuthRepository.tokenKey], 'token-jelle@example.com');
    expect(server.requests, contains('POST lists/import'));
    expect(lists.isSynced, isTrue);
    expect(lists.lists.single.name, 'Groceries');
    expect(lists.lists.single.items.single.name, 'Melk');
    expect(lists.messages.value, 'Moved to your account: Groceries');

    // The device copy is gone, so signing out shows an empty device.
    await deps.authController.signOut();
    expect(lists.isSynced, isFalse);
    expect(lists.lists, isEmpty);
    expect(store.values.containsKey(AuthRepository.tokenKey), isFalse);
  });

  test('a stored session is restored on start', () async {
    store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
    await deps.authController.restore();
    expect(deps.authController.isSignedIn, isTrue);
    expect(deps.shoppingListController.isSynced, isTrue);
  });

  test('an expired session signs out quietly', () async {
    store.values[AuthRepository.tokenKey] = 'token-gone@example.com';
    await deps.authController.restore();
    expect(deps.authController.isSignedIn, isFalse);
    expect(store.values.containsKey(AuthRepository.tokenKey), isFalse);
  });

  test('share a list and stop sharing', () async {
    server.addUser('anna@example.com', 'Anna');
    final lists = deps.shoppingListController;
    await lists.load();
    final list = (await lists.createList('Household'))!;
    await deps.authController.signIn('jelle@example.com', 'correct horse');

    expect(await lists.shareList(list.id, 'nobody@example.com'), isFalse);
    expect(lists.messages.value, 'No Baskit account with this email');

    expect(await lists.shareList(list.id, 'anna@example.com'), isTrue);
    final shared = lists.listById(list.id)!;
    expect(shared.isShared, isTrue);
    expect(shared.members.single.displayName, 'Anna');

    await lists.removeMember(list.id, shared.members.single.id);
    expect(lists.listById(list.id)!.members, isEmpty);
  });

  testWidgets('sign in from the profile tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(auth: deps.authController)),
    );
    expect(find.text('New here? Create an account'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'jelle@example.com',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Email or password is incorrect'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'correct horse',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('jelle@example.com'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Users and usage'), findsNothing);
  });

  testWidgets('admins see the admin menu', (tester) async {
    server.addUser('admin@example.com', 'Admin', role: 'admin');
    await deps.authController.signIn('admin@example.com', 'correct horse');
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(auth: deps.authController)),
    );
    expect(find.text('Admin'), findsWidgets);
    expect(find.text('Users and usage'), findsOneWidget);
  });

  testWidgets('create an account', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(auth: deps.authController)),
    );
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Anna');
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'anna@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'correct horse',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(deps.authController.user!.displayName, 'Anna');
    expect(find.text('anna@example.com'), findsOneWidget);
  });
}
