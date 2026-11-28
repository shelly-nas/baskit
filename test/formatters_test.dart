import 'package:baskit/backend/models/offer.dart';
import 'package:baskit/frontend/presentation/components/organisms/offer_card.dart';
import 'package:baskit/frontend/presentation/components/organisms/offer_details_sheet.dart';
import 'package:baskit/frontend/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dealLabel keeps the deal, not the explanation after "|"', () {
    test('cuts at the bar', () {
      expect(
        Formatters.dealLabel('50% KORTING | Alle AH Donuts van de bakkerij'),
        '50% KORTING',
      );
      expect(Formatters.dealLabel('2+3 GRATIS|bij Plus'), '2+3 GRATIS');
    });

    test('leaves a deal without a bar as it is, tidied', () {
      expect(Formatters.dealLabel('  2e halve   prijs '), '2e halve prijs');
    });

    test('keeps the text when nothing comes before the bar', () {
      expect(Formatters.dealLabel('| Alleen online'), 'Alleen online');
    });
  });

  final donuts = Offer(
    productId: 1,
    name: 'AH Mini donuts',
    category: 'Bakkerij',
    supermarket: const Supermarket(key: 'ah', name: 'Albert Heijn'),
    originalPrice: 0.30,
    price: 0.15,
    discountPercentage: 50,
    specialDiscount: '50% KORTING | Alle AH Donuts van de bakkerij',
    expireDate: DateTime.now().add(const Duration(days: 2)),
  );

  testWidgets('the card shows the short deal, the details the full text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfferCard(offer: donuts)),
      ),
    );
    expect(find.text('50% KORTING'), findsOneWidget);
    expect(find.textContaining('Alle AH Donuts'), findsNothing);
    expect(find.text('-50%'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfferDetailsSheet(offer: donuts)),
      ),
    );
    expect(
      find.text('50% KORTING | Alle AH Donuts van de bakkerij'),
      findsOneWidget,
    );
  });
}
