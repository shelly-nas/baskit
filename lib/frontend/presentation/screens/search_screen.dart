import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../backend/models/offer.dart';
import '../../../backend/services/offer_search_service.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../components/atoms/app_icon.dart';
import '../components/atoms/app_text.dart';
import '../components/molecules/filter_pill.dart';
import '../components/molecules/search_field.dart';
import '../components/organisms/offer_card.dart';
import '../components/organisms/offer_details_sheet.dart';

/// Search engine over all current supermarket offers from the discount API.
class SearchScreen extends StatefulWidget {
  final OfferSearchService service;
  final Duration debounce;

  const SearchScreen({
    super.key,
    required this.service,
    this.debounce = const Duration(milliseconds: 350),
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const double _maxContentWidth = 760;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  OfferQuery _query = const OfferQuery();
  List<Supermarket> _supermarkets = [];
  List<OfferCategory> _categories = [];
  final List<Offer> _offers = [];
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _error;

  // Incremented per search so responses of outdated searches are ignored.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFilters();
    _search();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final supermarkets = await widget.service.getSupermarkets();
      if (!mounted) return;
      setState(() => _supermarkets = supermarkets);
    } catch (_) {
      // Filters are optional; the search itself reports connection errors.
    }
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.service.getCategories(
        _query.supermarketKeys,
      );
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      // See _loadFilters.
    }
  }

  Future<void> _search() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await widget.service.search(_query);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _offers
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _hasMore = page.hasMore;
        _isLoading = false;
      });
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load offers. Check your connection and try again.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final requestId = _requestId;
    setState(() => _isLoadingMore = true);

    try {
      final page = await widget.service.search(_query, offset: _offers.length);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _offers.addAll(page.items);
        _total = page.total;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      if (text.trim() == _query.text.trim()) return;
      _query = _query.copyWith(text: text);
      _search();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    _query = _query.copyWith(text: '');
    _search();
  }

  void _toggleSupermarket(String key) {
    final keys = Set<String>.from(_query.supermarketKeys);
    if (!keys.remove(key)) keys.add(key);
    // A category may not exist for the new supermarket selection.
    _query = _query.copyWith(supermarketKeys: keys, clearCategory: true);
    _search();
    _loadCategories();
  }

  void _selectCategory(String? category) {
    _query = category == null
        ? _query.copyWith(clearCategory: true)
        : _query.copyWith(category: category);
    _search();
  }

  void _selectSort(OfferSort sort) {
    if (sort == _query.sort) return;
    _query = _query.copyWith(sort: sort);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: RefreshIndicator(
              onRefresh: _search,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spaceXLarge,
                      DesignTokens.space2XLarge,
                      DesignTokens.spaceXLarge,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(child: _buildHeader()),
                  ),
                  ..._buildResults(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('Search', fontSize: 28, fontWeight: FontWeight.w700),
        const SizedBox(height: DesignTokens.spaceSmall),
        const AppText(
          'Find the best offers across all supermarkets',
          fontSize: 14,
          color: AppColors.mutedForeground,
        ),
        const SizedBox(height: DesignTokens.spaceXLarge),
        SearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
          hintText: 'Search products, e.g. melk or koffie',
        ),
        const SizedBox(height: DesignTokens.spaceLarge),
        if (_supermarkets.isNotEmpty) _buildSupermarketFilter(),
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spaceMedium),
          _buildCategoryFilter(),
        ],
        const SizedBox(height: DesignTokens.spaceLarge),
        _buildResultsBar(),
        const SizedBox(height: DesignTokens.spaceMedium),
      ],
    );
  }

  Widget _buildSupermarketFilter() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _supermarkets.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: DesignTokens.spaceMedium),
        itemBuilder: (context, index) {
          final supermarket = _supermarkets[index];
          return Center(
            child: FilterPill(
              label: supermarket.name,
              accentColor: AppColors.supermarket(supermarket.key),
              isSelected: _query.supermarketKeys.contains(supermarket.key),
              onTap: () => _toggleSupermarket(supermarket.key),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        separatorBuilder: (_, _) =>
            const SizedBox(width: DesignTokens.spaceMedium),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: FilterPill(
                label: 'All categories',
                isSelected: _query.category == null,
                onTap: () => _selectCategory(null),
              ),
            );
          }
          final category = _categories[index - 1];
          return Center(
            child: FilterPill(
              label: category.name,
              isSelected: _query.category == category.name,
              onTap: () => _selectCategory(category.name),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsBar() {
    return Row(
      children: [
        Expanded(
          child: AppText(
            _isLoading && _offers.isEmpty
                ? 'Searching...'
                : '$_total ${_total == 1 ? 'offer' : 'offers'}',
            fontSize: 13,
            color: AppColors.mutedForeground,
          ),
        ),
        PopupMenuButton<OfferSort>(
          tooltip: 'Sort',
          initialValue: _query.sort,
          onSelected: _selectSort,
          color: AppColors.card,
          itemBuilder: (context) => [
            for (final sort in OfferSort.values)
              PopupMenuItem(value: sort, child: Text(sort.label)),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceMedium,
              vertical: DesignTokens.spaceSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(
                  CupertinoIcons.arrow_up_arrow_down,
                  size: DesignTokens.iconSmall,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: DesignTokens.spaceSmall),
                AppText(
                  _query.sort.label,
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildResults() {
    if (_isLoading && _offers.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageState(
            icon: CupertinoIcons.wifi_exclamationmark,
            title: 'Something went wrong',
            message: _error!,
            actionLabel: 'Try again',
            onAction: _search,
          ),
        ),
      ];
    }

    if (_offers.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageState(
            icon: CupertinoIcons.search,
            title: 'No offers found',
            message: _query.text.isEmpty
                ? 'There are no active offers for these filters.'
                : 'No offers match "${_query.text}". Try another word or remove filters.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceXLarge,
        ),
        sliver: SliverList.separated(
          itemCount: _offers.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: DesignTokens.spaceMedium),
          itemBuilder: (context, index) {
            final offer = _offers[index];
            return OfferCard(
              offer: offer,
              onTap: () => OfferDetailsSheet.show(context, offer),
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space2XLarge),
          child: Center(
            child: _isLoadingMore
                ? const CircularProgressIndicator(strokeWidth: 2)
                : _hasMore
                ? TextButton(
                    onPressed: _loadMore,
                    child: const Text('Load more'),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space3XLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            icon,
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: DesignTokens.spaceXLarge),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
