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
    final List<ShoppingList> shoppingLists = [
      ShoppingList(
        name: 'Weekly Groceries',
        icon: CupertinoIcons.shopping_cart,
        itemCount: 12,
        completedItems: 5,
        isShared: true,
        memberCount: 3,
      ),
      ShoppingList(
        name: 'Party Supplies',
        icon: CupertinoIcons.gift,
        itemCount: 8,
        completedItems: 0,
        isShared: false,
      ),
      ShoppingList(
        name: 'Camping Trip',
        icon: CupertinoIcons.compass,
        itemCount: 15,
        completedItems: 3,
        isShared: true,
        memberCount: 4,
      ),
      ShoppingList(
        name: 'Pantry Restock',
        icon: CupertinoIcons.cube_box,
        itemCount: 20,
        completedItems: 20,
        isShared: false,
      ),
      ShoppingList(
        name: 'Holiday Dinner',
        icon: CupertinoIcons.star,
        itemCount: 25,
        completedItems: 12,
        isShared: true,
        memberCount: 2,
      ),
    ];

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
