import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../backend/models/user_account.dart';
import '../../../database/data_sources/baskit_api_client.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../components/atoms/app_badge.dart';
import '../components/atoms/app_icon.dart';
import '../components/atoms/app_text.dart';
import '../controllers/auth_controller.dart';

enum _UserAction { makeAdmin, removeAdmin, disable, enable }

/// Admin overview: usage numbers and the accounts, with role and access.
class AdminScreen extends StatefulWidget {
  final AuthController auth;

  const AdminScreen({super.key, required this.auth});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const _statLabels = {
    'users': 'Accounts',
    'active_users': 'Active accounts',
    'users_last_30_days': 'Signed in, 30 days',
    'lists': 'Lists',
    'shared_lists': 'Shared lists',
    'items': 'Items',
  };

  Map<String, int> _stats = {};
  List<UserAccount> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = widget.auth.repository;
      final results = await Future.wait([
        repository.adminStats(),
        repository.adminUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, int>;
        _users = results[1] as List<UserAccount>;
        _loading = false;
      });
    } on BaskitApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _apply(UserAccount user, _UserAction action) async {
    try {
      await widget.auth.repository.adminUpdateUser(
        user.id,
        role: switch (action) {
          _UserAction.makeAdmin => 'admin',
          _UserAction.removeAdmin => 'user',
          _ => null,
        },
        isActive: switch (action) {
          _UserAction.disable => false,
          _UserAction.enable => true,
          _ => null,
        },
      );
      await _load();
    } on BaskitApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.auth.user;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const AppText(
          'Users and usage',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(_error!, color: AppColors.destructive),
                      const SizedBox(height: DesignTokens.spaceLarge),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
                    children: [
                      Wrap(
                        spacing: DesignTokens.spaceLarge,
                        runSpacing: DesignTokens.spaceLarge,
                        children: [
                          for (final entry in _statLabels.entries)
                            _StatTile(
                              label: entry.value,
                              value: _stats[entry.key] ?? 0,
                            ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space2XLarge),
                      const AppText(
                        'Accounts',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: DesignTokens.spaceMedium),
                      for (final user in _users)
                        _UserRow(
                          user: user,
                          isMe: user.id == me?.id,
                          onAction: (action) => _apply(user, action),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(DesignTokens.spaceLarge),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(label, fontSize: 12, color: AppColors.mutedForeground),
          const SizedBox(height: DesignTokens.spaceSmall),
          AppText('$value', fontSize: 22, fontWeight: FontWeight.w700),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserAccount user;
  final bool isMe;
  final ValueChanged<_UserAction> onAction;

  const _UserRow({
    required this.user,
    required this.isMe,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final lastSeen = user.lastLoginAt;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: user.isActive
                    ? AppColors.foreground
                    : AppColors.mutedForeground,
              ),
            ),
          ),
          if (user.isAdmin) ...[
            const SizedBox(width: DesignTokens.spaceMedium),
            const AppBadge(
              text: 'Admin',
              backgroundColor: AppColors.secondary,
              textColor: AppColors.foreground,
              borderRadius: DesignTokens.radiusSmall,
            ),
          ],
          if (!user.isActive) ...[
            const SizedBox(width: DesignTokens.spaceMedium),
            const AppBadge(
              text: 'Disabled',
              backgroundColor: AppColors.warningBackground,
              textColor: AppColors.warning,
              borderRadius: DesignTokens.radiusSmall,
            ),
          ],
        ],
      ),
      subtitle: Text(
        [
          user.email,
          '${user.listCount ?? 0} lists',
          if (lastSeen != null)
            'last sign-in ${lastSeen.day}-${lastSeen.month}-${lastSeen.year}',
        ].join('  /  '),
        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
      ),
      trailing: isMe
          ? null
          : PopupMenuButton<_UserAction>(
              tooltip: 'Account options',
              color: AppColors.card,
              icon: const AppIcon(
                CupertinoIcons.ellipsis,
                color: AppColors.mutedForeground,
              ),
              onSelected: onAction,
              itemBuilder: (context) => [
                user.isAdmin
                    ? const PopupMenuItem(
                        value: _UserAction.removeAdmin,
                        child: Text('Remove admin role'),
                      )
                    : const PopupMenuItem(
                        value: _UserAction.makeAdmin,
                        child: Text('Make admin'),
                      ),
                user.isActive
                    ? const PopupMenuItem(
                        value: _UserAction.disable,
                        child: Text('Disable account'),
                      )
                    : const PopupMenuItem(
                        value: _UserAction.enable,
                        child: Text('Enable account'),
                      ),
              ],
            ),
    );
  }
}
