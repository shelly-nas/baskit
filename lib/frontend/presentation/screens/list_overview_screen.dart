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
  late List<ShoppingList> _shoppingLists;

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  void _loadShoppingLists() {
    // TODO: Load shopping lists from backend
    _shoppingLists = [];
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
