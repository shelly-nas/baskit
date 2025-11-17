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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: shoppingLists.length,
          itemBuilder: (context, index) {
            final list = shoppingLists[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE9E9E7), width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Navigate to list details
                  },
                  borderRadius: BorderRadius.circular(4),
                  hoverColor: const Color(0xFFF1F1EF),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          list.icon,
                          size: 20,
                          color: const Color(0xFF787774),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            list.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF37352F),
                            ),
                          ),
                        ),
                        Text(
                          '${list.itemCount} items',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF787774),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
