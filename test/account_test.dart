import 'package:baskit/database/data_sources/baskit_api_client.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/repositories/auth_repository.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/frontend/presentation/controllers/auth_controller.dart';
import 'package:baskit/frontend/presentation/screens/profile_screen.dart';
import 'package:baskit/main.dart';
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

  AuthController auth() => deps.authController;

  group('session', () {
    test('without a stored token the user has to sign in', () async {
      expect(auth().status, AuthStatus.restoring);
      await auth().restore();
      expect(auth().status, AuthStatus.signedOut);
      expect(server.requests, isEmpty);
    });

    test('signing in keeps the token and loads the account lists', () async {
      await auth().restore();
      await auth().signIn('jelle@example.com', 'correct horse');

      expect(auth().status, AuthStatus.signedIn);
      expect(auth().user!.displayName, 'Jelle');
      expect(store.values[AuthRepository.tokenKey], 'token-jelle@example.com');
      expect(deps.shoppingListController.hasLoaded, isTrue);

      final list = (await deps.shoppingListController.createList('Weekend'))!;
      await deps.shoppingListController.addItem(list.id, 'Melk');
      expect(server.lists[list.id]!['items'], hasLength(1));
    });

    test('a stored session is restored on start', () async {
      store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      await auth().restore();
      expect(auth().status, AuthStatus.signedIn);
      expect(auth().user!.email, 'jelle@example.com');
    });

    test('an expired session goes back to sign-in quietly', () async {
      store.values[AuthRepository.tokenKey] = 'token-gone@example.com';
      await auth().restore();
      expect(auth().status, AuthStatus.signedOut);
      expect(store.values.containsKey(AuthRepository.tokenKey), isFalse);
    });

    test('an unreachable server keeps the token for a retry', () async {
      store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      server.offline = true;
      await auth().restore();
      expect(auth().status, AuthStatus.unreachable);
      expect(store.values[AuthRepository.tokenKey], 'token-jelle@example.com');

      server.offline = false;
      await auth().restore();
      expect(auth().status, AuthStatus.signedIn);
    });

    test('a token rejected during use signs out', () async {
      await auth().signIn('jelle@example.com', 'correct horse');
      // For example an admin disabled the account.
      server.users.remove('jelle@example.com');

      await deps.shoppingListController.load();
      await pumpEventQueue();

      expect(auth().status, AuthStatus.signedOut);
      expect(store.values.containsKey(AuthRepository.tokenKey), isFalse);
    });

    test('signing out forgets the token and the lists', () async {
      await auth().signIn('jelle@example.com', 'correct horse');
      await deps.shoppingListController.createList('Weekend');

      await auth().signOut();

      expect(auth().status, AuthStatus.signedOut);
      expect(deps.shoppingListController.lists, isEmpty);
      expect(store.values.containsKey(AuthRepository.tokenKey), isFalse);
    });

    test('delete the account', () async {
      await auth().signIn('jelle@example.com', 'correct horse');

      await expectLater(
        auth().deleteAccount('wrong'),
        throwsA(isA<BaskitApiException>()),
      );
      expect(auth().status, AuthStatus.signedIn);

      await auth().deleteAccount('correct horse');
      expect(auth().status, AuthStatus.signedOut);
      expect(server.users.containsKey('jelle@example.com'), isFalse);
      expect(store.values.containsKey(AuthRepository.tokenKey), isFalse);
    });
  });

  test('share a list and stop sharing', () async {
    server.addUser('anna@example.com', 'Anna');
    await auth().signIn('jelle@example.com', 'correct horse');
    final lists = deps.shoppingListController;
    final list = (await lists.createList('Household'))!;

    expect(await lists.shareList(list.id, 'nobody@example.com'), isFalse);
    expect(lists.messages.value, 'No Baskit account with this email');

    expect(await lists.shareList(list.id, 'anna@example.com'), isTrue);
    final shared = lists.listById(list.id)!;
    expect(shared.isShared, isTrue);
    expect(shared.members.single.displayName, 'Anna');

    await lists.removeMember(list.id, shared.members.single.id);
    expect(lists.listById(list.id)!.members, isEmpty);
  });

  group('app', () {
    Future<void> startApp(WidgetTester tester) async {
      // Same order as main(): restore runs while the app shows a loader.
      final restoring = auth().restore();
      await tester.pumpWidget(BaskitApp(dependencies: deps));
      await restoring;
      await tester.pumpAndSettle();
    }

    Future<void> signIn(WidgetTester tester, String password) async {
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'jelle@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        password,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();
    }

    testWidgets('starts on the sign-in screen and opens after sign-in', (
      tester,
    ) async {
      await startApp(tester);
      expect(find.text('New here? Create an account'), findsOneWidget);
      expect(find.text('Profile'), findsNothing);

      await signIn(tester, 'wrong');
      expect(find.text('Email or password is incorrect'), findsOneWidget);

      await signIn(tester, 'correct horse');
      expect(
        find.text('Find the best offers across all supermarkets'),
        findsOneWidget,
      );
    });

    testWidgets('stays signed in on the next start', (tester) async {
      store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      await startApp(tester);
      expect(
        find.text('Find the best offers across all supermarkets'),
        findsOneWidget,
      );
      expect(find.text('New here? Create an account'), findsNothing);
    });

    testWidgets('signing out returns to the sign-in screen', (tester) async {
      store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      await startApp(tester);

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('create an account', (tester) async {
      await startApp(tester);
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

      expect(auth().user!.displayName, 'Anna');
      expect(
        find.text('Find the best offers across all supermarkets'),
        findsOneWidget,
      );
    });

    testWidgets('offers a retry when the server is unreachable', (
      tester,
    ) async {
      store.values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      server.offline = true;
      await startApp(tester);
      expect(
        find.text('Could not reach Baskit. Check your connection.'),
        findsOneWidget,
      );

      server.offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(
        find.text('Find the best offers across all supermarkets'),
        findsOneWidget,
      );
    });
  });

  group('profile', () {
    testWidgets('members do not see the admin menu', (tester) async {
      await auth().signIn('jelle@example.com', 'correct horse');
      await tester.pumpWidget(MaterialApp(home: ProfileScreen(auth: auth())));
      expect(find.text('jelle@example.com'), findsOneWidget);
      expect(find.text('Member'), findsOneWidget);
      expect(find.text('Users and usage'), findsNothing);
    });

    testWidgets('admins see the admin menu', (tester) async {
      server.addUser('admin@example.com', 'Admin', role: 'admin');
      await auth().signIn('admin@example.com', 'correct horse');
      await tester.pumpWidget(MaterialApp(home: ProfileScreen(auth: auth())));
      expect(find.text('Admin'), findsWidgets);
      expect(find.text('Users and usage'), findsOneWidget);
    });

    testWidgets('delete the account after entering the password', (
      tester,
    ) async {
      await auth().signIn('jelle@example.com', 'correct horse');
      await tester.pumpWidget(MaterialApp(home: ProfileScreen(auth: auth())));

      await tester.ensureVisible(find.text('Delete account'));
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'correct horse');
      await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
      await tester.pumpAndSettle();

      expect(auth().status, AuthStatus.signedOut);
      expect(server.users.containsKey('jelle@example.com'), isFalse);
    });
  });
}
