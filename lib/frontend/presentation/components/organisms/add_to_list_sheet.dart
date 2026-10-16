import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../backend/models/offer.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../controllers/shopping_list_controller.dart';
import '../../dialogs/text_input_dialog.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';

/// Lets the user pick the shopping list an offer is added to.
///
/// Returns the name of the list the offer was added to, or null when the
/// user cancelled.
Future<String?> showAddToListSheet(
  BuildContext context, {
  required ShoppingListController controller,
  required Offer offer,
}) async {
  await controller.ensureLoaded();
  if (!context.mounted) return null;

  final listId = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.card,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusXLarge),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.space2XLarge,
                DesignTokens.spaceMedium,
                DesignTokens.space2XLarge,
                DesignTokens.spaceMedium,
              ),
              child: AppText(
                'Add to list',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final list in controller.lists)
                    ListTile(
                      leading: const AppIcon(
                        CupertinoIcons.list_bullet,
                        color: AppColors.mutedForeground,
                      ),
                      title: Text(list.name),
                      subtitle: Text(
                        '${list.itemCount} '
                        '${list.itemCount == 1 ? 'item' : 'items'}',
                      ),
                      onTap: () => Navigator.of(sheetContext).pop(list.id),
                    ),
                  ListTile(
                    leading: const AppIcon(
                      CupertinoIcons.add,
                      color: AppColors.mutedForeground,
                    ),
                    title: const Text('New list'),
                    onTap: () async {
                      final name = await showTextInputDialog(
                        sheetContext,
                        title: 'New list',
                        confirmLabel: 'Create',
                        initialValue: controller.lists.isEmpty
                            ? 'Groceries'
                            : '',
                        hintText: 'List name',
                      );
                      if (name == null) return;
                      final list = await controller.createList(name);
                      if (list != null && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop(list.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (listId == null) return null;
  await controller.addOffer(listId, offer);
  return controller.listById(listId)?.name;
}
