import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/repositories/auth_repository.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/frontend/presentation/screens/admin_screen.dart';
import 'package:baskit/frontend/presentation/screens/list_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_baskit_server.dart';
import 'support/fake_offer_repository.dart';

void main() {
  late FakeBaskitServer server;
  late AppDependencies app;

  Future<void> signInAs(String email) async {
    final store = InMemoryStore()
      ..values[AuthRepository.tokenKey] = 'token-$email';
    app = AppDependencies.create(
      store: store,
      baskitApi: server.client(),
      offerRepository: FakeOfferRepository(),
    );
    await app.authController.restore();
  }

  setUp(() {
    server = FakeBaskitServer()
      ..addUser('admin@example.com', 'Admin', role: 'admin')
      ..addUser('anna@example.com', 'Anna');
  });

  group('admin', () {
    Future<void> openAdmin(WidgetTester tester) async {
      await signInAs('admin@example.com');
      await tester.pumpWidget(
        MaterialApp(home: AdminScreen(auth: app.authController)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pick(WidgetTester tester, String action) async {
      // The admin's own row has no options, so this is Anna's.
      await tester.tap(find.byTooltip('Account options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the usage numbers and the accounts', (tester) async {
      await openAdmin(tester);

      expect(find.text('Users and usage'), findsOneWidget);
      expect(find.text('Active accounts'), findsOneWidget);
      expect(find.textContaining('anna@example.com'), findsOneWidget);
      expect(find.byTooltip('Account options'), findsOneWidget);
    });

    testWidgets('disable and enable an account', (tester) async {
      await openAdmin(tester);

      await pick(tester, 'Disable account');
      expect(server.users['anna@example.com']!['is_active'], isFalse);
      expect(find.text('Disabled'), findsOneWidget);

      await pick(tester, 'Enable account');
      expect(server.users['anna@example.com']!['is_active'], isTrue);
      expect(find.text('Disabled'), findsNothing);
    });

    testWidgets('make an account admin and take it back', (tester) async {
      await openAdmin(tester);

      await pick(tester, 'Make admin');
      expect(server.users['anna@example.com']!['role'], 'admin');

      await pick(tester, 'Remove admin role');
      expect(server.users['anna@example.com']!['role'], 'user');
    });

    testWidgets('a failure to load offers a retry', (tester) async {
      await signInAs('admin@example.com');
      server.offline = true;
      await tester.pumpWidget(
        MaterialApp(home: AdminScreen(auth: app.authController)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);

      server.offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.textContaining('anna@example.com'), findsOneWidget);
    });
  });

  group('sharing', () {
    Future<void> openShareSheet(WidgetTester tester) async {
      await signInAs('admin@example.com');
      final list = await app.shoppingListController.createList('Weekend');
      await tester.pumpWidget(
        MaterialApp(
          home: ListDetailScreen(
            controller: app.shoppingListController,
            listId: list!.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('List options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
    }

    Future<void> shareWith(WidgetTester tester, String email) async {
      await tester.enterText(
        find.widgetWithText(TextField, 'Email address'),
        email,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Share'));
      await tester.pumpAndSettle();
    }

    testWidgets('share a list and stop sharing it', (tester) async {
      await openShareSheet(tester);
      expect(find.text('Share "Weekend"'), findsOneWidget);
      expect(find.text('Not shared yet.'), findsOneWidget);

      await shareWith(tester, 'anna@example.com');
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Not shared yet.'), findsNothing);

      await tester.tap(find.byTooltip('Stop sharing with Anna'));
      await tester.pumpAndSettle();
      expect(find.text('Not shared yet.'), findsOneWidget);
    });

    testWidgets('an unknown email is explained', (tester) async {
      await openShareSheet(tester);

      await shareWith(tester, 'nobody@example.com');

      // Shown in the snack bar of the main screen.
      expect(
        app.shoppingListController.messages.value,
        'No Baskit account with this email',
      );
      expect(find.text('Not shared yet.'), findsOneWidget);
    });
  });
}
