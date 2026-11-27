import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../../backend/models/favorite.dart';
import '../../theme/design_tokens.dart';
import '../../utils/formatters.dart';
import '../components/atoms/app_icon.dart';
import '../components/atoms/app_text.dart';
import '../controllers/favorites_controller.dart';

/// The user's favorites: add new ones and remove ones no longer bought.
class FavoritesScreen extends StatefulWidget {
  final FavoritesController favorites;

  const FavoritesScreen({super.key, required this.favorites});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    _name.clear();
    await widget.favorites.add(name);
  }

  /// The quantity, and where the favorite is on offer now (FR-010).
  Widget? _subtitle(Favorite favorite) {
    final deal = widget.favorites.dealFor(favorite.id);
    final quantity = favorite.quantity;
    if (deal == null) return quantity == null ? null : Text(quantity);
    final offer = deal.offer;
    return Text(
      [
        ?quantity,
        'On offer at ${offer.supermarket.name}: '
            '${Formatters.price(offer.price)} (${offer.name})',
      ].join('  /  '),
      style: const TextStyle(color: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: widget.favorites,
        builder: (context, _) {
          final favorites = widget.favorites.favorites;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
                children: [
                  const AppText(
                    'Items you buy often. In a list, tap one to put it on.',
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(height: DesignTokens.spaceLarge),
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(
                      hintText: 'Add a favorite',
                      isDense: true,
                      suffixIcon: IconButton(
                        tooltip: 'Add favorite',
                        onPressed: _add,
                        icon: const AppIcon(
                          CupertinoIcons.add,
                          size: DesignTokens.iconMedium,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMedium),
                  if (favorites.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(DesignTokens.space2XLarge),
                      child: AppText(
                        'No favorites yet. You can also add one from an item '
                        'on a list.',
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final favorite in favorites)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(favorite.name),
                      subtitle: _subtitle(favorite),
                      trailing: IconButton(
                        tooltip: 'Remove ${favorite.name} from favorites',
                        onPressed: () => widget.favorites.remove(favorite.id),
                        icon: const AppIcon(
                          CupertinoIcons.delete,
                          size: DesignTokens.iconMedium,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
