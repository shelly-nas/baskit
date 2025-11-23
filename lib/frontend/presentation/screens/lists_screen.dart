import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../components/organisms/shopping_list_card_component.dart';
import '../components/molecules/list_header.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: Load shopping lists from backend
    final List<ShoppingList> shoppingLists = [];

    return Scaffold(
      appBar: AppBar(
        title: ListHeader(
          title: 'Shopping Lists',
          onAddPressed: () {
            // Add new list
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: shoppingLists.length,
        itemBuilder: (context, index) {
          final list = shoppingLists[index];
          return ShoppingListCardComponent(
            list: list,
            onTap: () {
              // Navigate to list details
            },
          );
        },
      ),
    );
  }
}
