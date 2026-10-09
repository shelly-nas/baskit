import 'package:flutter/material.dart';
import '../../../backend/services/offer_search_service.dart';
import 'lists_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../components/organisms/bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  final OfferSearchService offerSearchService;

  const MainScreen({super.key, required this.offerSearchService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions = <Widget>[
    SearchScreen(service: widget.offerSearchService),
    const ListsScreen(),
    const ProfileScreen(),
  ];

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
