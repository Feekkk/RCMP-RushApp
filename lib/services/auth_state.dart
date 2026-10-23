import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Roles recognised by the app's route guards (see `router/app_router.dart`).
/// `guest` means nobody is signed in.
enum UserRole { guest, student, staff, admin, hod, vendor }

UserRole roleFromString(String? value) {
  switch ((value ?? '').toLowerCase().trim()) {
    case 'student':
      return UserRole.student;
    case 'staff':
      return UserRole.staff;
    case 'admin':
      return UserRole.admin;
    case 'hod':
      return UserRole.hod;
    case 'vendor':
      return UserRole.vendor;
    default:
      return UserRole.guest;
  }
}

/// App-wide auth session. Portals call [login] once they've confirmed who
/// the user is; dashboards call [logout] on sign-out. `GoRouter` listens to
/// this (via `refreshListenable`) so its redirect guard re-runs whenever the
/// session changes.
class AuthState extends ChangeNotifier {
  AuthState._internal();
  static final AuthState instance = AuthState._internal();

  static const _prefRole = 'auth_role';
  static const _prefEmail = 'auth_email';
  static const _prefFullName = 'auth_full_name';

  UserRole role = UserRole.guest;
  String? email;
  String? fullName;
  Map<String, dynamic> extra = const {};

  bool get isLoggedIn => role != UserRole.guest;

  /// Loads a previously-persisted session, if any. Call once at startup
  /// (before `runApp`) so the first route guard check already knows who's
  /// signed in.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    role = roleFromString(prefs.getString(_prefRole));
    email = prefs.getString(_prefEmail);
    fullName = prefs.getString(_prefFullName);
  }

  Future<void> login({
    required UserRole role,
    String? email,
    String? fullName,
    Map<String, dynamic> extra = const {},
  }) async {
    this.role = role;
    this.email = email;
    this.fullName = fullName;
    this.extra = extra;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRole, role.name);
    await prefs.setString(_prefEmail, email ?? '');
    await prefs.setString(_prefFullName, fullName ?? '');
  }

  Future<void> logout() async {
    role = UserRole.guest;
    email = null;
    fullName = null;
    extra = const {};
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefRole);
    await prefs.remove(_prefEmail);
    await prefs.remove(_prefFullName);
  }
}
