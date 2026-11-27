import 'package:baskit/backend/models/favorite.dart';
import 'package:baskit/backend/services/favorite_deals_service.dart';
import 'package:baskit/backend/services/offer_search_service.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/repositories/auth_repository.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/frontend/presentation/screens/favorites_screen.dart';
import 'package:baskit/frontend/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_baskit_server.dart';
import 'support/fake_offer_repository.dart';

void main() {
  const melk = Favorite(id: 'f1', name: 'Melk');
  const kipfilet = Favorite(id: 'f2', name: 'Kipfilet');
  const thee = Favorite(id: 'f3', name: 'Thee');

  group('service', () {
    late FakeOfferRepository repository;
    late FavoriteDealsService deals;

    setUp(() {
      repository = FakeOfferRepository();
      deals = FavoriteDealsService(OfferSearchService(repository));
    });

    test('finds the current offer for each favorite that has one', () async {
      final found = await deals.dealsFor([melk, kipfilet, thee]);

      expect(found.map((d) => d.favorite.name), ['Melk', 'Kipfilet']);
      expect(found.first.offer.isOnOffer, isTrue);
      expect(repository.queries.every((q) => q.offersOnly), isTrue);
    });

    test('asks again only after a while or for other favorites', () async {
      final now = DateTime(2026, 11, 27, 12);
      await deals.dealsFor([melk], now: now);
      await deals.dealsFor([melk], now: now.add(const Duration(minutes: 5)));
      expect(repository.queries, hasLength(1));

      await deals.dealsFor([
        melk,
        thee,
      ], now: now.add(const Duration(minutes: 6)));
      await deals.dealsFor([
        melk,
        thee,
      ], now: now.add(const Duration(hours: 1)));
      expect(repository.queries, hasLength(1 + 2 + 2));
    });

    test('without the offers service there are no deals, no error', () async {
      repository.fail = true;
      expect(await deals.dealsFor([melk]), isEmpty);
    });
  });

  group('screens', () {
    late FakeBaskitServer server;
    late AppDependencies app;

    Future<void> signIn() async {
      server = FakeBaskitServer()..addUser('jelle@example.com', 'Jelle');
      server.favorites['f1'] = {'id': 'f1', 'name': 'Melk', 'quantity': null};
      server.favorites['f3'] = {'id': 'f3', 'name': 'Thee', 'quantity': null};
      final store = InMemoryStore()
        ..values[AuthRepository.tokenKey] = 'token-jelle@example.com';
      app = AppDependencies.create(
        store: store,
        baskitApi: server.client(),
        offerRepository: FakeOfferRepository(),
      );
      await app.authController.restore();
    }

    testWidgets('the search tab shows the favorites on offer', (tester) async {
      await signIn();
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(
            service: app.offerSearchService,
            listController: app.shoppingListController,
            favorites: app.favoritesController,
            debounce: Duration.zero,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your favorites on offer'), findsOneWidget);
      final deal = find.byKey(const ValueKey('deal-f1'));
      expect(deal, findsOneWidget);

      await tester.tap(deal);
      await tester.pumpAndSettle();
      expect(find.text('Add to list'), findsOneWidget);

      // While searching the section makes room for the results.
      // Close the details sheet by tapping outside it.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'kip');
      await tester.pumpAndSettle();
      expect(find.text('Your favorites on offer'), findsNothing);
    });

    testWidgets('the favorites screen says which ones are on offer', (
      tester,
    ) async {
      await signIn();
      await tester.pumpWidget(
        MaterialApp(home: FavoritesScreen(favorites: app.favoritesController)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('On offer at Dirk'), findsOneWidget);
      expect(find.textContaining('On offer'), findsOneWidget);
    });
  });
}
