import 'package:baskit/backend/services/offer_search_service.dart';
import 'package:baskit/frontend/presentation/screens/lists_screen.dart';
import 'package:baskit/frontend/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_offer_repository.dart';
import 'support/test_shopping_lists.dart';

void main() {
  testWidgets('create a list, add and check off an item', (tester) async {
    final controller = createShoppingListController();
    await tester.pumpWidget(
      MaterialApp(home: ListsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No lists yet'), findsOneWidget);

    await tester.tap(find.text('Create list'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Weekend');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Opens the new list.
    expect(find.text('Weekend'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Coffee');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(controller.lists.single.itemCount, 1);

    await tester.tap(find.bySemanticsLabel('Mark as done'));
    await tester.pumpAndSettle();

    expect(find.text('Completed (1)'), findsOneWidget);
    expect(controller.lists.single.completedItemsCount, 1);
  });

  // The E2E scenarios find widgets through the accessibility tree.
  testWidgets('the new-list button and list cards have accessible labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = createShoppingListController();
    await tester.pumpWidget(
      MaterialApp(home: ListsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New list'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Weekend');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The card is a tappable list entry, not a progress bar.
    final card = tester
        .getSemantics(find.textContaining('items completed'))
        .getSemanticsData();
    expect(card.label, contains('Weekend'));
    expect(card.hasAction(SemanticsAction.tap), isTrue);
    expect(card.value, isEmpty, reason: 'no progress value on the card');
    expect(find.bySemanticsLabel(RegExp('Weekend')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('add an offer to a new list from search', (tester) async {
    final controller = createShoppingListController();
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(
          service: OfferSearchService(FakeOfferRepository()),
          listController: controller,
          debounce: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kipfilet 500g'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New list'));
    await tester.pumpAndSettle();
    // Prefilled with "Groceries" for the first list.
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Added to Groceries'), findsOneWidget);
    final item = controller.lists.single.items.single;
    expect(item.name, 'Kipfilet 500g');
    expect(item.offer!.price, 3.99);
    expect(item.offer!.supermarketName, 'Dirk');
  });
}
