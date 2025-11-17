import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/shopping_list.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ShoppingList> shoppingLists = [
      ShoppingList(
        name: 'Groceries',
        icon: CupertinoIcons.shopping_cart,
        itemCount: 5,
      ),
      ShoppingList(
        name: 'Hardware Store',
        icon: CupertinoIcons.wrench,
        itemCount: 2,
      ),
      ShoppingList(
        name: 'Pharmacy',
        icon: CupertinoIcons.bandage,
        itemCount: 3,
      ),
      ShoppingList(name: 'Pet Store', icon: CupertinoIcons.paw, itemCount: 1),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Lists')),
      body: ListView.builder(
        itemCount: shoppingLists.length,
        itemBuilder: (context, index) {
          final list = shoppingLists[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(0),
            ),
            child: ListTile(
              leading: Icon(list.icon),
              title: Text(list.name),
              trailing: Text('${list.itemCount} items'),
              onTap: () {
                // Navigate to list details
              },
            ),
          );
        },
      ),
    );
  }
}
