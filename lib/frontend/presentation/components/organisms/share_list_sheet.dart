import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../controllers/shopping_list_controller.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';

/// Owner view of who a list is shared with; add people by their account email.
Future<void> showShareListSheet(
  BuildContext context, {
  required ShoppingListController controller,
  required String listId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusXLarge),
      ),
    ),
    builder: (_) => _ShareListSheet(controller: controller, listId: listId),
  );
}

class _ShareListSheet extends StatefulWidget {
  final ShoppingListController controller;
  final String listId;

  const _ShareListSheet({required this.controller, required this.listId});

  @override
  State<_ShareListSheet> createState() => _ShareListSheetState();
}

class _ShareListSheetState extends State<_ShareListSheet> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    final added = await widget.controller.shareList(widget.listId, email);
    if (!mounted) return;
    setState(() => _busy = false);
    if (added) _email.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space2XLarge),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final list = widget.controller.listById(widget.listId);
              if (list == null) return const SizedBox.shrink();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Share "${list.name}"',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: DesignTokens.spaceSmall),
                  const AppText(
                    'People you share with can add, check off and remove '
                    'items. They need a Baskit account.',
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(height: DesignTokens.spaceXLarge),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _busy ? null : _add(),
                          decoration: const InputDecoration(
                            hintText: 'Email address',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceMedium),
                      ElevatedButton(
                        onPressed: _busy ? null : _add,
                        child: const Text('Share'),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceXLarge),
                  if (list.members.isEmpty)
                    const AppText(
                      'Not shared yet.',
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                    ),
                  for (final member in list.members)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const AppIcon(
                        CupertinoIcons.person,
                        color: AppColors.mutedForeground,
                      ),
                      title: Text(member.displayName),
                      subtitle: member.email == null
                          ? null
                          : Text(member.email!),
                      trailing: IconButton(
                        tooltip: 'Stop sharing with ${member.displayName}',
                        icon: const AppIcon(
                          CupertinoIcons.xmark,
                          size: DesignTokens.iconMedium,
                          color: AppColors.mutedForeground,
                        ),
                        onPressed: () => widget.controller.removeMember(
                          widget.listId,
                          member.id,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
