import 'package:flutter/foundation.dart';

import '../../../backend/models/user_account.dart';
import '../../../database/data_sources/baskit_api_client.dart';
import '../../../database/repositories/auth_repository.dart';
import 'shopping_list_controller.dart';

/// Where the app is in signing in; decides which screen the app shows.
enum AuthStatus {
  /// Checking the stored token on start.
  restoring,

  /// No (valid) token: the sign-in screen.
  signedOut,

  /// The server could not be reached on start; the token is kept.
  unreachable,

  /// Signed in: the app itself.
  signedIn,
}

/// The signed-in account. The app needs one: lists live on the server.
///
/// The token stays on the device until the user signs out or the server
/// rejects it, so a user stays signed in between visits.
class AuthController extends ChangeNotifier {
  final AuthRepository _repository;
  final ShoppingListController _lists;

  AuthController({
    required AuthRepository repository,
    required ShoppingListController lists,
  }) : _repository = repository,
       _lists = lists;

  AuthStatus _status = AuthStatus.restoring;
  UserAccount? _user;
  bool _isBusy = false;
  String? _restoreError;

  AuthStatus get status => _status;
  UserAccount? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isBusy => _isBusy;

  /// Why the stored session could not be checked ([AuthStatus.unreachable]).
  String? get restoreError => _restoreError;

  /// Restores the stored session on app start.
  Future<void> restore() async {
    _setStatus(AuthStatus.restoring);
    try {
      final user = await _repository.restore();
      if (user == null) {
        _setStatus(AuthStatus.signedOut);
      } else {
        await _enterAccount(user);
      }
    } on BaskitApiException catch (e) {
      if (e.isUnauthorized) {
        // The repository already dropped the rejected token.
        _setStatus(AuthStatus.signedOut);
      } else {
        _restoreError = e.message;
        _setStatus(AuthStatus.unreachable);
      }
    }
  }

  /// Throws [BaskitApiException] with a message for the user on failure.
  Future<void> signIn(String email, String password) => _busy(
    () async => _enterAccount(await _repository.signIn(email, password)),
  );

  Future<void> register(String email, String password, String displayName) =>
      _busy(
        () async => _enterAccount(
          await _repository.register(email, password, displayName),
        ),
      );

  Future<void> signOut() => _busy(() async {
    await _repository.signOut();
    _leaveAccount();
  });

  /// Throws [BaskitApiException] when the password is wrong.
  Future<void> deleteAccount(String password) => _busy(() async {
    await _repository.deleteAccount(password);
    _leaveAccount();
  });

  /// The server rejected the token during use: back to the sign-in screen.
  Future<void> handleUnauthorized() async {
    if (_status != AuthStatus.signedIn) return;
    await _repository.signOut();
    _leaveAccount();
  }

  Future<void> updateProfile({
    String? displayName,
    String? currentPassword,
    String? newPassword,
  }) => _busy(() async {
    _user = await _repository.updateProfile(
      displayName: displayName,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  });

  AuthRepository get repository => _repository;

  Future<void> _enterAccount(UserAccount user) async {
    _user = user;
    _restoreError = null;
    _setStatus(AuthStatus.signedIn);
    await _lists.load();
  }

  void _leaveAccount() {
    _user = null;
    _lists.reset();
    _setStatus(AuthStatus.signedOut);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  Future<void> _busy(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
