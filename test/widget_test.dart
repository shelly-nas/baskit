import 'package:baskit/backend/models/offer.dart';
import 'package:baskit/backend/services/offer_search_service.dart';
import 'package:baskit/frontend/presentation/screens/search_screen.dart';
import 'package:baskit/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_offer_repository.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/di/dependency_injection.dart';

void main() {
  late FakeOfferRepository repository;
  late OfferSearchService service;

  setUp(() {
    repository = FakeOfferRepository();
    service = OfferSearchService(repository);
  });

  Future<void> pumpSearch(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(service: service, debounce: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('app opens on the search tab', (tester) async {
    await tester.pumpWidget(
      BaskitApp(
        dependencies: AppDependencies.create(
          store: InMemoryStore(),
          offerRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Find the best offers across all supermarkets'),
      findsOneWidget,
    );
    expect(find.text('Halfvolle melk 1L'), findsOneWidget);
  });

  testWidgets('shows all offers and supermarkets with offers first', (
    tester,
  ) async {
    await pumpSearch(tester);

    expect(find.text('3 offers'), findsOneWidget);
    expect(find.text('Kipfilet 500g'), findsOneWidget);

    final pills = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .toList();
    expect(pills, ['Dirk', 'Jumbo', 'Aldi']);
  });

  testWidgets('typing searches the API', (tester) async {
    await pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'melk');
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();

    expect(repository.queries.last.text, 'melk');
    expect(find.text('2 offers'), findsOneWidget);
    expect(find.text('Kipfilet 500g'), findsNothing);
  });

  testWidgets('supermarket filter narrows results', (tester) async {
    await pumpSearch(tester);

    await tester.tap(find.text('Jumbo'));
    await tester.pumpAndSettle();

    expect(repository.queries.last.supermarketKeys, {'jumbo'});
    expect(find.text('1 offer'), findsOneWidget);
    expect(find.text('Melkchocolade reep'), findsOneWidget);
  });

  testWidgets('sort selection is sent to the API', (tester) async {
    await pumpSearch(tester);

    await tester.tap(find.text(OfferSort.relevance.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OfferSort.price.label).last);
    await tester.pumpAndSettle();

    expect(repository.queries.last.sort, OfferSort.price);
  });

  testWidgets('shows an error state with retry', (tester) async {
    repository.fail = true;
    await pumpSearch(tester);

    expect(find.text('Something went wrong'), findsOneWidget);

    repository.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('3 offers'), findsOneWidget);
  });

  testWidgets('tapping an offer opens its details', (tester) async {
    await pumpSearch(tester);

    await tester.tap(find.text('Kipfilet 500g'));
    await tester.pumpAndSettle();

    expect(find.text('Regular price'), findsOneWidget);
    expect(find.text('You save'), findsOneWidget);
  });
}
