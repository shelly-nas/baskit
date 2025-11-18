import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../../theme/design_tokens.dart';

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
        title: const Text('Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.add_circled_solid,
              size: DesignTokens.iconXLarge,
            ),
            onPressed: () {
              // Add new list
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: shoppingLists.length,
        itemBuilder: (context, index) {
          final list = shoppingLists[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE9E9E7),
                width: DesignTokens.borderThin,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate to list details
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  list.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF37352F),
                                  ),
                                ),
                                if (list.isShared) ...[
                                  const SizedBox(
                                    width: DesignTokens.spaceMedium,
                                  ),
                                  const Icon(
                                    CupertinoIcons.person_2,
                                    size: DesignTokens.iconSmall,
                                    color: Color(0xFF787774),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Items info
                      Text(
                        '${list.completedItems}/${list.itemCount} items completed',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF787774),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: list.completionPercentage,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F1EF),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF37352F),
                          ),
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
    );
  }
}
