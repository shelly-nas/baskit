import 'dart:async';

import 'package:flutter/material.dart';
import '../../../di/dependency_injection.dart';
import 'lists_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../../../database/data_sources/offline_shopping_list_data_source.dart';
import '../components/molecules/offline_banner.dart';
import '../components/organisms/bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  final AppDependencies dependencies;

  const MainScreen({super.key, required this.dependencies});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  AppDependencies get _deps => widget.dependencies;

  late final List<Widget> _widgetOptions = <Widget>[
    SearchScreen(
      service: _deps.offerSearchService,
      listController: _deps.shoppingListController,
    ),
    ListsScreen(
      controller: _deps.shoppingListController,
      comparisonService: _deps.priceComparisonService,
      suggestions: _deps.itemSuggestionService,
    ),
    ProfileScreen(auth: _deps.authController),
  ];

  @override
  void initState() {
    super.initState();
    _deps.shoppingListController.messages.addListener(_showMessage);
    // Shared lists stay current while the app is open: someone else may be
    // checking off items in the same shop.
    WidgetsBinding.instance.addObserver(this);
    _deps.shoppingListController.startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deps.shoppingListController.stopAutoRefresh();
    _deps.shoppingListController.messages.removeListener(_showMessage);
    super.dispose();
  }

  /// No requests while the app or browser tab is in the background; catch up
  /// at once when it comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lists = _deps.shoppingListController;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(lists.refresh());
        lists.startAutoRefresh();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        lists.stopAutoRefresh();
      case AppLifecycleState.inactive:
        // Briefly, e.g. behind a system dialog: keep refreshing.
        break;
    }
  }

  void _showMessage() {
    final message = _deps.shoppingListController.messages.value;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ValueListenableBuilder<SyncStatus>(
            valueListenable: _deps.shoppingListController.syncStatus,
            builder: (context, sync, _) => sync.isOffline || sync.pending > 0
                ? OfflineBanner(pending: sync.pending)
                : const SizedBox.shrink(),
          ),
          Expanded(
            // IndexedStack keeps the search state when switching tabs.
            child: IndexedStack(
              index: _selectedIndex,
              children: _widgetOptions,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
