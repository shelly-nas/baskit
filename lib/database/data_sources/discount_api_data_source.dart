import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../backend/models/offer.dart';
import '../models/offer_dto.dart';

/// Remote data source for the discount-scraper public API.
class DiscountApiDataSource {
  final Uri _baseUri;
  final http.Client _client;
  final Duration _timeout;

  DiscountApiDataSource({
    required Uri baseUri,
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) : _baseUri = baseUri,
       _client = client ?? http.Client(),
       _timeout = timeout;

  Future<List<Supermarket>> getSupermarkets() async {
    final json = await _get('supermarkets') as List<dynamic>;
    return json
        .map((e) => OfferDto.supermarketFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OfferCategory>> getCategories({
    Set<String> supermarketKeys = const {},
  }) async {
    final json =
        await _get('categories', {
              if (supermarketKeys.isNotEmpty)
                'supermarket': supermarketKeys.join(','),
            })
            as List<dynamic>;
    return json
        .map((e) => OfferDto.categoryFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OfferPage> search(
    OfferQuery query, {
    int limit = 25,
    int offset = 0,
  }) async {
    final json =
        await _get('search', {
              if (query.text.trim().isNotEmpty) 'q': query.text.trim(),
              if (query.supermarketKeys.isNotEmpty)
                'supermarket': query.supermarketKeys.join(','),
              if (query.category != null) 'category': query.category!,
              'sort': query.sort.apiValue,
              'limit': '$limit',
              'offset': '$offset',
            })
            as Map<String, dynamic>;
    return OfferDto.pageFromJson(json);
  }

  Future<dynamic> _get(String path, [Map<String, String>? params]) async {
    final base = _baseUri.path.endsWith('/')
        ? _baseUri
        : _baseUri.replace(path: '${_baseUri.path}/');
    final uri = base
        .resolve(path)
        .replace(
          queryParameters: params == null || params.isEmpty ? null : params,
        );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } catch (e) {
      throw DiscountApiException('Could not reach the discount service', e);
    }

    if (response.statusCode != 200) {
      throw DiscountApiException(
        'Discount service responded with ${response.statusCode}',
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

class DiscountApiException implements Exception {
  final String message;
  final Object? cause;

  DiscountApiException(this.message, [this.cause]);

  @override
  String toString() => 'DiscountApiException: $message';
}
