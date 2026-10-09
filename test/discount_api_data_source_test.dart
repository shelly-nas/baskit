import 'dart:convert';

import 'package:baskit/backend/models/offer.dart';
import 'package:baskit/database/data_sources/discount_api_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final searchResponse = {
    'query': 'melk',
    'total': 30,
    'limit': 25,
    'offset': 0,
    'items': [
      {
        'id': 1,
        'name': 'Halfvolle melk 1L',
        'category': 'Zuivel',
        'supermarket': {'key': 'dirk', 'name': 'Dirk'},
        'productUrl': 'https://www.dirk.nl/aanbiedingen',
        'discount': {
          'id': 10,
          'originalPrice': 1.09,
          'discountPrice': 0.79,
          'unitPrice': '€0.79/l',
          'specialDiscount': null,
          'discountPercentage': 28,
          'expireDate': '2026-10-12T21:59:59.000Z',
        },
        'updatedAt': '2026-10-09T08:00:00.000Z',
      },
      {
        'id': 2,
        'name': 'Volle melk',
        'category': 'Zuivel',
        'supermarket': {'key': 'aldi', 'name': 'Aldi'},
        'productUrl': null,
        'discount': {
          'id': 11,
          'originalPrice': null,
          'discountPrice': 1,
          'unitPrice': null,
          'specialDiscount': '2e halve prijs',
          'discountPercentage': null,
          'expireDate': '2026-10-12T21:59:59.000Z',
        },
        'updatedAt': '2026-10-09T08:00:00.000Z',
      },
    ],
  };

  test('search builds the query string and parses the response', () async {
    late Uri requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response.bytes(utf8.encode(jsonEncode(searchResponse)), 200);
    });
    final dataSource = DiscountApiDataSource(
      baseUri: Uri.parse('https://example.com/api/discounts'),
      client: client,
    );

    final page = await dataSource.search(
      const OfferQuery(
        text: ' melk ',
        supermarketKeys: {'dirk', 'aldi'},
        category: 'Zuivel',
        sort: OfferSort.price,
      ),
      offset: 25,
    );

    expect(requested.path, '/api/discounts/search');
    expect(requested.queryParameters, {
      'q': 'melk',
      'supermarket': 'dirk,aldi',
      'category': 'Zuivel',
      'sort': 'price',
      'limit': '25',
      'offset': '25',
    });
    expect(page.total, 30);
    expect(page.items, hasLength(2));
    expect(page.hasMore, isTrue);

    final first = page.items.first;
    expect(first.name, 'Halfvolle melk 1L');
    expect(first.supermarket.key, 'dirk');
    expect(first.originalPrice, 1.09);
    expect(first.unitPrice, '\u20AC0.79/l');
    expect(first.discountPrice, 0.79);
    expect(first.discountPercentage, 28);
    expect(first.savings, closeTo(0.30, 0.001));

    final second = page.items.last;
    expect(second.originalPrice, isNull);
    expect(second.discountPrice, 1.0);
    expect(second.specialDiscount, '2e halve prijs');
    expect(second.savings, isNull);
  });

  test('supermarkets are parsed', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'http://localhost:3001/api/public/v1/supermarkets',
      );
      return http.Response(
        jsonEncode([
          {
            'key': 'albert-heijn',
            'name': 'Albert Heijn',
            'activeDiscounts': 412,
            'lastUpdated': '2026-10-09T08:00:00.000Z',
            'expireDate': null,
          },
        ]),
        200,
      );
    });
    final dataSource = DiscountApiDataSource(
      baseUri: Uri.parse('http://localhost:3001/api/public/v1/'),
      client: client,
    );

    final supermarkets = await dataSource.getSupermarkets();

    expect(supermarkets.single.name, 'Albert Heijn');
    expect(supermarkets.single.activeDiscounts, 412);
    expect(supermarkets.single.lastUpdated, isNotNull);
  });

  test('non 200 responses throw a DiscountApiException', () async {
    final dataSource = DiscountApiDataSource(
      baseUri: Uri.parse('https://example.com/api/discounts'),
      client: MockClient((_) async => http.Response('{"error":"x"}', 500)),
    );

    expect(dataSource.getCategories(), throwsA(isA<DiscountApiException>()));
  });
}
