import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../backend/models/shopping_list.dart';
import '../../../backend/services/price_comparison_service.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../../utils/formatters.dart';
import '../components/atoms/app_icon.dart';
import '../components/atoms/app_text.dart';
import '../components/organisms/list_item_row.dart';
import '../components/organisms/share_list_sheet.dart';
import '../controllers/shopping_list_controller.dart';
import '../dialogs/text_input_dialog.dart';
import 'price_comparison_screen.dart';

enum _DetailAction { rename, share, clearCompleted, delete, leave }

enum _ItemAction { quantity, remove }

/// One shopping list: add items, check them off, remove them.
class ListDetailScreen extends StatefulWidget {
  final ShoppingListController controller;
  final String listId;

  /// Enables "Compare prices" when set.
  final PriceComparisonService? comparisonService;

  const ListDetailScreen({
    super.key,
    required this.controller,
    required this.listId,
    this.comparisonService,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  static const double _maxContentWidth = 760;

  final TextEditingController _newItemController = TextEditingController();
  final FocusNode _newItemFocus = FocusNode();

  // Swiped away items are hidden at once; the controller removes them async.
  final Set<String> _dismissedIds = {};

  ShoppingListController get _controller => widget.controller;

  @override
  void dispose() {
    _newItemController.dispose();
    _newItemFocus.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _newItemController.text.trim();
    if (name.isEmpty) return;
    _newItemController.clear();
    await _controller.addItem(widget.listId, name);
    _newItemFocus.requestFocus();
  }

  Future<void> _onItemTap(ListItem item) async {
    final action = await showModalBottomSheet<_ItemAction>(
      context: context,
      backgroundColor: AppColors.card,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: AppText(item.name, fontWeight: FontWeight.w600)),
            ListTile(
              leading: const AppIcon(CupertinoIcons.number),
              title: const Text('Set quantity'),
              onTap: () => Navigator.of(sheetContext).pop(_ItemAction.quantity),
            ),
            ListTile(
              leading: const AppIcon(
                CupertinoIcons.delete,
                color: AppColors.destructive,
              ),
              title: const Text(
                'Remove from list',
                style: TextStyle(color: AppColors.destructive),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_ItemAction.remove),
            ),
          ],
        ),
      ),
    );
    switch (action) {
      case _ItemAction.quantity:
        await _editQuantity(item);
      case _ItemAction.remove:
        await _controller.deleteItem(widget.listId, item.id);
      case null:
        break;
    }
  }

  Future<void> _editQuantity(ListItem item) async {
    final quantity = await showTextInputDialog(
      context,
      title: 'Quantity for ${item.name}',
      confirmLabel: 'Save',
      initialValue: item.quantity ?? '',
      hintText: 'e.g. 2, 500 g, 1 pack',
    );
    if (quantity == null) return;
    await _controller.updateItem(
      widget.listId,
      item.copyWith(quantity: quantity),
    );
  }

  Future<void> _onAction(ShoppingList list, _DetailAction action) async {
    switch (action) {
      case _DetailAction.rename:
        final name = await showTextInputDialog(
          context,
          title: 'Rename list',
          confirmLabel: 'Save',
          initialValue: list.name,
        );
        if (name != null) await _controller.renameList(list.id, name);
      case _DetailAction.share:
        await showShareListSheet(
          context,
          controller: _controller,
          listId: list.id,
        );
      case _DetailAction.leave:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Leave list',
          message:
              'Stop seeing "${list.name}"? ${list.owner?.displayName ?? 'The owner'} '
              'can share it with you again.',
          confirmLabel: 'Leave',
        );
        if (!confirmed) return;
        await _controller.leaveList(list.id);
        if (mounted) Navigator.of(context).pop();
      case _DetailAction.clearCompleted:
        await _controller.clearCompleted(list.id);
      case _DetailAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete list',
          message: 'Delete "${list.name}" and all its items?',
          confirmLabel: 'Delete',
        );
        if (!confirmed) return;
        await _controller.deleteList(list.id);
        if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final list = _controller.listById(widget.listId);
        if (list == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This list no longer exists.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(list.name, fontSize: 18, fontWeight: FontWeight.w700),
                if (_sharingLine(list) != null)
                  AppText(
                    _sharingLine(list)!,
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
              ],
            ),
            actions: [
              if (widget.comparisonService != null &&
                  list.uncompletedItems.isNotEmpty)
                TextButton.icon(
                  icon: const AppIcon(
                    CupertinoIcons.chart_bar_alt_fill,
                    size: DesignTokens.iconMedium,
                  ),
                  label: const Text(
                    'Compare prices',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.foreground,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PriceComparisonScreen(
                        list: list,
                        service: widget.comparisonService!,
                      ),
                    ),
                  ),
                ),
              PopupMenuButton<_DetailAction>(
                tooltip: 'List options',
                color: AppColors.card,
                icon: const AppIcon(CupertinoIcons.ellipsis),
                onSelected: (action) => _onAction(list, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _DetailAction.rename,
                    child: Text('Rename'),
                  ),
                  if (list.isOwner)
                    const PopupMenuItem(
                      value: _DetailAction.share,
                      child: Text('Share'),
                    ),
                  if (list.completedItems.isNotEmpty)
                    const PopupMenuItem(
                      value: _DetailAction.clearCompleted,
                      child: Text('Remove completed items'),
                    ),
                  list.isOwner
                      ? const PopupMenuItem(
                          value: _DetailAction.delete,
                          child: Text('Delete list'),
                        )
                      : const PopupMenuItem(
                          value: _DetailAction.leave,
                          child: Text('Leave list'),
                        ),
                ],
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
                children: [
                  if (list.offerItems.isNotEmpty) _buildOfferSummary(list),
                  _buildNewItemField(),
                  const SizedBox(height: DesignTokens.spaceMedium),
                  for (final item in list.uncompletedItems)
                    if (!_dismissedIds.contains(item.id)) _buildRow(item),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(DesignTokens.space2XLarge),
                      child: AppText(
                        'This list is empty. Type an item above, or add '
                        'offers from the Search tab.',
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (list.completedItems.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.space2XLarge),
                    AppText(
                      'Completed (${list.completedItems.length})',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(height: DesignTokens.spaceSmall),
                    for (final item in list.completedItems)
                      if (!_dismissedIds.contains(item.id)) _buildRow(item),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// "Shared by Anna" for a list shared with you, "Shared with 2 people"
  /// for your own shared list.
  String? _sharingLine(ShoppingList list) {
    if (!list.isOwner && list.owner != null) {
      return 'Shared by ${list.owner!.displayName}';
    }
    final count = list.members.length;
    if (count == 0) return null;
    return count == 1
        ? 'Shared with ${list.members.single.displayName}'
        : 'Shared with $count people';
  }

  Widget _buildOfferSummary(ShoppingList list) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceXLarge),
      padding: const EdgeInsets.all(DesignTokens.spaceLarge),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Row(
        children: [
          const AppIcon(
            CupertinoIcons.tag,
            size: DesignTokens.iconMedium,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: DesignTokens.spaceMedium),
          Expanded(
            child: AppText(
              '${list.offerItems.length} '
              '${list.offerItems.length == 1 ? 'item' : 'items'} on offer',
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
          AppText(
            Formatters.price(list.offerTotal),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildNewItemField() {
    return TextField(
      controller: _newItemController,
      focusNode: _newItemFocus,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _addItem(),
      decoration: InputDecoration(
        hintText: 'Add an item',
        isDense: true,
        prefixIcon: const AppIcon(
          CupertinoIcons.add,
          size: DesignTokens.iconMedium,
          color: AppColors.mutedForeground,
        ),
        suffixIcon: IconButton(
          tooltip: 'Add',
          onPressed: _addItem,
          icon: const AppIcon(
            CupertinoIcons.arrow_turn_down_left,
            size: DesignTokens.iconMedium,
            color: AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(ListItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: DesignTokens.spaceXLarge),
        color: AppColors.destructive,
        child: const AppIcon(
          CupertinoIcons.delete,
          color: AppColors.destructiveForeground,
        ),
      ),
      onDismissed: (_) {
        setState(() => _dismissedIds.add(item.id));
        _controller.deleteItem(widget.listId, item.id);
      },
      child: ListItemRow(
        item: item,
        onToggle: () => _controller.toggleItem(widget.listId, item),
        onTap: () => _onItemTap(item),
      ),
    );
  }
}
