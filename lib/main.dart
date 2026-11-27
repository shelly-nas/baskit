import 'package:flutter/material.dart';

import 'database/data_sources/offline_shopping_list_data_source.dart';
import 'di/dependency_injection.dart';
import 'frontend/presentation/components/molecules/offline_banner.dart';
import 'frontend/presentation/screens/auth_gate.dart';
import 'frontend/theme/theme.dart';

void main() {
  final dependencies = AppDependencies.create();
  // Signed in before? The stored token is checked while a loader shows.
  dependencies.authController.restore();
  runApp(BaskitApp(dependencies: dependencies));
}

class BaskitApp extends StatelessWidget {
  final AppDependencies dependencies;

  const BaskitApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baskit - Smart Shopping Lists',
      theme: AppTheme.lightTheme,
      home: AuthGate(dependencies: dependencies),
      debugShowCheckedModeBanner: false,
      // Above every screen, also an open list on top of the tabs: that is
      // where the user is when the connection drops in the shop.
      builder: (context, child) => ValueListenableBuilder<SyncStatus>(
        valueListenable: dependencies.shoppingListController.syncStatus,
        child: child,
        // The same widgets whether or not the banner shows, so the screens
        // below (and the open list) keep their state.
        builder: (context, sync, screen) {
          final show = sync.isOffline || sync.pending > 0;
          return Column(
            children: [
              if (show) Material(child: OfflineBanner(pending: sync.pending)),
              Expanded(
                // The banner already keeps clear of the status bar.
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: show,
                  child: screen ?? const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
