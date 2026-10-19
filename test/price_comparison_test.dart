import 'dart:convert';

import 'package:baskit/backend/models/price_comparison.dart';
import 'package:baskit/backend/services/price_comparison_service.dart';
import 'package:baskit/database/data_sources/discount_api_data_source.dart';
import 'package:baskit/frontend/presentation/screens/lists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_offer_repository.dart';
import 'support/test_shopping_lists.dart';

void main() {
  test('counts are read from simple quantities only', () {
    expect(PriceComparisonService.countFromQuantity(null), 1);
    expect(PriceComparisonService.countFromQuantity('2'), 2);
    expect(PriceComparisonService.countFromQuantity('3x'), 3);
    expect(PriceComparisonService.countFromQuantity('4 stuks'), 4);
    expect(PriceComparisonService.countFromQuantity('500 g'), 1);
    expect(PriceComparisonService.countFromQuantity('1 pack'), 1);
    expect(PriceComparisonService.countFromQuantity('0'), 1);
  });

  test('compare posts the items and parses the stores', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'itemCount': 2,
            'supermarkets': [
              {
                'key': 'dirk',
                'name': 'Dirk',
                'total': 2.37,
                'matched': 1,
                'missing': ['b'],
                'lines': [
                  {
                    'itemId': 'a',
                    'count': 3,
                    'lineTotal': 2.37,
                    'product': {
                      'name': 'Halfvolle melk 1L',
                      'price': 0.79,
                      'productUrl': null,
                      'discount': {'specialDiscount': '2 voor 1,50'},
                    },
                  },
                  {
                    'itemId': 'b',
                    'count': 1,
                    'lineTotal': null,
                    'product': null,
                  },
                ],
              },
            ],
          }),
        ),
        200,
      );
    });
    final dataSource = DiscountApiDataSource(
      baseUri: Uri.parse('https://example.com/api/discounts'),
      client: client,
    );

    final result = await dataSource.compare(const [
      CompareRequestItem(id: 'a', query: 'melk', count: 3, productId: 7),
      CompareRequestItem(id: 'b', query: 'brood'),
    ]);

    expect(sent.method, 'POST');
    expect(sent.url.path, '/api/discounts/compare');
    expect(jsonDecode(sent.body), {
      'items': [
        {'id': 'a', 'query': 'melk', 'count': 3, 'productId': 7},
        {'id': 'b', 'query': 'brood', 'count': 1},
      ],
    });
    final store = result.best!;
    expect(store.supermarket.name, 'Dirk');
    expect(store.total, 2.37);
    expect(store.lineFor('a')!.isOffer, isTrue);
    expect(store.lineFor('a')!.specialDiscount, '2 voor 1,50');
    expect(store.lineFor('b')!.isFound, isFalse);
  });

  testWidgets('compare prices from a list', (tester) async {
    final repository = FakeOfferRepository();
    final controller = createShoppingListController();
    await controller.load();
    final list = (await controller.createList('Weekend'))!;
    await controller.addItem(list.id, 'Melk', quantity: '2');
    await controller.addItem(list.id, 'Brood');
    await controller.addItem(list.id, 'Kaas');
    final kaas = controller.listById(list.id)!.items.last;
    await controller.toggleItem(list.id, kaas);

    await tester.pumpWidget(
      MaterialApp(
        home: ListsScreen(
          controller: controller,
          comparisonService: PriceComparisonService(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compare prices'));
    await tester.pumpAndSettle();

    // Checked items are not compared; quantity 2 becomes a count.
    final sent = repository.comparisons.single;
    expect(sent.map((i) => i.query), ['Melk', 'Brood']);
    expect(sent.first.count, 2);

    expect(find.text('Best choice'), findsOneWidget);
    expect(find.text('All 2 items found'), findsOneWidget);
    expect(find.text('1 of 2 items found'), findsOneWidget);
    // Aldi found nothing and is not shown.
    expect(find.text('Aldi'), findsNothing);
    // Dirk: 2 x 0.50 + 0.50
    expect(find.text('€1,50'), findsOneWidget);
    expect(find.text('2 x Melk'), findsOneWidget);
  });
}
