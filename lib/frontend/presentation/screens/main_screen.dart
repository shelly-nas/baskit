import 'package:flutter/material.dart';
import '../../../di/dependency_injection.dart';
import 'lists_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../components/organisms/bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  final AppDependencies dependencies;

  const MainScreen({super.key, required this.dependencies});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
    ),
    ProfileScreen(auth: _deps.authController),
  ];

  @override
  void initState() {
    super.initState();
    _deps.shoppingListController.messages.addListener(_showMessage);
  }

  @override
  void dispose() {
    _deps.shoppingListController.messages.removeListener(_showMessage);
    super.dispose();
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
      // IndexedStack keeps the search state when switching tabs.
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
