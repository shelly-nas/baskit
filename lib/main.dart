import 'package:baskit/frontend/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'backend/services/offer_search_service.dart';
import 'frontend/theme/theme.dart';
import 'di/dependency_injection.dart';

void main() {
  // Initialize dependency injection
  final di = DependencyInjection()..initialize();

  runApp(BaskitApp(offerSearchService: di.offerSearchService));
}

class BaskitApp extends StatelessWidget {
  final OfferSearchService offerSearchService;

  const BaskitApp({super.key, required this.offerSearchService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baskit - Smart Shopping Lists',
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme,
      // themeMode: ThemeMode.light,
      home: MainScreen(offerSearchService: offerSearchService),
      debugShowCheckedModeBanner: false,
    );
  }
}
