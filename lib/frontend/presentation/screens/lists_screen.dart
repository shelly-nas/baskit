import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../backend/models/shopping_list.dart';
import '../../../backend/services/price_comparison_service.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../components/atoms/app_icon.dart';
import '../components/atoms/app_text.dart';
import '../components/molecules/list_header.dart';
import '../components/organisms/shopping_list_card_component.dart';
import '../controllers/shopping_list_controller.dart';
import '../dialogs/text_input_dialog.dart';
import 'list_detail_screen.dart';

enum _ListAction { rename, delete, leave }

class ListsScreen extends StatefulWidget {
  final ShoppingListController controller;
  final PriceComparisonService? comparisonService;

  const ListsScreen({
    super.key,
    required this.controller,
    this.comparisonService,
  });

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  static const double _maxContentWidth = 760;

  ShoppingListController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.ensureLoaded();
  }

  Future<void> _createList() async {
    final name = await showTextInputDialog(
      context,
      title: 'New list',
      confirmLabel: 'Create',
      hintText: 'e.g. Weekly groceries',
    );
    if (name == null) return;
    final list = await _controller.createList(name);
    if (list != null && mounted) _openList(list);
  }

  void _openList(ShoppingList list) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListDetailScreen(
          controller: _controller,
          listId: list.id,
          comparisonService: widget.comparisonService,
        ),
      ),
    );
  }

  Future<void> _onAction(ShoppingList list, _ListAction action) async {
    switch (action) {
      case _ListAction.rename:
        final name = await showTextInputDialog(
          context,
          title: 'Rename list',
          confirmLabel: 'Save',
          initialValue: list.name,
        );
        if (name != null) await _controller.renameList(list.id, name);
      case _ListAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete list',
          message: 'Delete "${list.name}" and all its items?',
          confirmLabel: 'Delete',
        );
        if (confirmed) await _controller.deleteList(list.id);
      case _ListAction.leave:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Leave list',
          message: 'Stop seeing "${list.name}"?',
          confirmLabel: 'Leave',
        );
        if (confirmed) await _controller.leaveList(list.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListHeader(title: 'Lists', onAddPressed: _createList),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final lists = _controller.lists;
          final Widget body;
          if (!_controller.hasLoaded) {
            body = const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          } else if (_controller.error != null) {
            body = _EmptyState(
              title: 'Something went wrong',
              message: _controller.error!,
              actionLabel: 'Try again',
              onAction: _controller.load,
            );
          } else if (lists.isEmpty) {
            body = _EmptyState(
              title: 'No lists yet',
              message:
                  'Create a list, or add offers to one from the Search tab.',
              actionLabel: 'Create list',
              onAction: _createList,
            );
          } else {
            body = ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return ShoppingListCardComponent(
                  list: list,
                  onTap: () => _openList(list),
                  trailing: PopupMenuButton<_ListAction>(
                    tooltip: 'List options',
                    color: AppColors.card,
                    icon: const AppIcon(
                      CupertinoIcons.ellipsis,
                      color: AppColors.mutedForeground,
                    ),
                    onSelected: (action) => _onAction(list, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: _ListAction.rename,
                        child: Text('Rename'),
                      ),
                      list.isOwner
                          ? const PopupMenuItem(
                              value: _ListAction.delete,
                              child: Text('Delete'),
                            )
                          : const PopupMenuItem(
                              value: _ListAction.leave,
                              child: Text('Leave'),
                            ),
                    ],
                  ),
                );
              },
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: body,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space3XLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppIcon(
            CupertinoIcons.list_bullet,
            size: DesignTokens.iconXLarge,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(height: DesignTokens.spaceLarge),
          AppText(title, fontSize: 16, fontWeight: FontWeight.w500),
          const SizedBox(height: DesignTokens.spaceSmall),
          AppText(
            message,
            fontSize: 14,
            color: AppColors.mutedForeground,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spaceXLarge),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
