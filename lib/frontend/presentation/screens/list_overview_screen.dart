import 'package:flutter/material.dart';
import '../../../backend/models/shopping_list.dart';
import '../widgets/shopping_list_card.dart';
import '../../theme/app_theme.dart';

/// List Overview Screen
/// Displays all shopping lists for the user
class ListOverviewScreen extends StatefulWidget {
  const ListOverviewScreen({super.key});

  @override
  State<ListOverviewScreen> createState() => _ListOverviewScreenState();
}

class _ListOverviewScreenState extends State<ListOverviewScreen> {
  // Mock data for demonstration (will be replaced with backend data later)
  late List<ShoppingList> _shoppingLists;

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  void _loadShoppingLists() {
    // Mock data based on the functional document
    _shoppingLists = [
      ShoppingList(
        id: '1',
        name: 'Weekly Groceries',
        description: 'Regular weekly shopping',
        isShared: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        items: [
          ListItem(
            id: '1',
            name: 'Milk',
            quantity: '2L',
            category: 'Dairy',
            isCompleted: true,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ListItem(
            id: '2',
            name: 'Bread',
            quantity: '2',
            category: 'Bakery',
            isCompleted: true,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ListItem(
            id: '3',
            name: 'Apples',
            quantity: '1kg',
            category: 'Fruits',
            isCompleted: false,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ListItem(
            id: '4',
            name: 'Chicken breast',
            quantity: '500g',
            category: 'Meat',
            isCompleted: false,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
      ShoppingList(
        id: '2',
        name: 'Party Supplies',
        description: 'Items for birthday party on Saturday',
        isShared: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          ListItem(
            id: '5',
            name: 'Chips',
            quantity: '3 bags',
            category: 'Snacks',
            isCompleted: false,
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          ListItem(
            id: '6',
            name: 'Soft drinks',
            quantity: '2L x 4',
            category: 'Beverages',
            isCompleted: false,
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          ListItem(
            id: '7',
            name: 'Paper plates',
            quantity: '20 pieces',
            category: 'Party',
            isCompleted: false,
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
      ),
      ShoppingList(
        id: '3',
        name: 'Personal Care',
        description: null,
        isShared: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        items: [
          ListItem(
            id: '8',
            name: 'Toothpaste',
            quantity: '1',
            category: 'Personal Care',
            isCompleted: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          ListItem(
            id: '9',
            name: 'Shampoo',
            quantity: '1',
            category: 'Personal Care',
            isCompleted: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      ),
      ShoppingList(
        id: '4',
        name: 'Quick Stop',
        description: 'Items for tonight\'s dinner',
        isShared: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          ListItem(
            id: '10',
            name: 'Pasta',
            quantity: '500g',
            category: 'Pantry',
            isCompleted: false,
            createdAt: DateTime.now(),
          ),
          ListItem(
            id: '11',
            name: 'Tomato sauce',
            quantity: '1 jar',
            category: 'Pantry',
            isCompleted: false,
            createdAt: DateTime.now(),
          ),
          ListItem(
            id: '12',
            name: 'Parmesan cheese',
            quantity: '100g',
            category: 'Dairy',
            isCompleted: false,
            createdAt: DateTime.now(),
          ),
        ],
      ),
    ];
  }

  void _onListTap(ShoppingList list) {
    // TODO: Navigate to list detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening "${list.name}"...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onAddList() {
    // TODO: Navigate to create list screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new list functionality coming soon...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Search lists',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show menu
            },
            tooltip: 'More options',
          ),
        ],
      ),
      body: _shoppingLists.isEmpty ? _buildEmptyState() : _buildListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddList,
        tooltip: 'Create new list',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 80,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'No Shopping Lists',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Create your first shopping list to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton.icon(
              onPressed: _onAddList,
              icon: const Icon(Icons.add),
              label: const Text('Create List'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                  vertical: AppTheme.spacingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh logic
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _loadShoppingLists();
        });
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppTheme.spacingMedium,
          bottom: 80, // Space for FAB
        ),
        itemCount: _shoppingLists.length,
        itemBuilder: (context, index) {
          final list = _shoppingLists[index];
          return ShoppingListCard(
            shoppingList: list,
            onTap: () => _onListTap(list),
          );
        },
      ),
    );
  }
}
