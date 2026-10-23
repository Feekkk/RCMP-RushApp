import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_state.dart';
import '../theme/app_theme.dart';

/// DEV ONLY. While this is `true`, every "Sign in with Microsoft" button
/// skips the real backend/OAuth call and logs straight in via [devLogin]
/// using whichever role is picked on a [DevRoleSwitcher]. Flip to `false`
/// (or delete this file and its call sites in `user_login_screen.dart` and
/// `operator_portal_screen.dart`) once the real backend/SSO flow is ready.
const bool kDevAuthBypass = true;

/// Logs straight into [role] via [AuthState] (no network call) and jumps to
/// that role's landing screen, mirroring what each portal's real login
/// handler does on success.
Future<void> devLogin(BuildContext context, UserRole role,
    {String? department}) async {
  final String roleLabel = role.name;
  final String fullName =
      'Dev ${roleLabel[0].toUpperCase()}${roleLabel.substring(1)}';
  final String email = 'dev.$roleLabel@unikl.edu.my';

  await AuthState.instance.login(role: role, email: email, fullName: fullName);
  if (!context.mounted) return;

  switch (role) {
    case UserRole.admin:
      context.pushReplacement('/admin/dashboard',
          extra: {'email': email, 'full_name': fullName, 'role': 'ADMIN'});
      break;
    case UserRole.hod:
      context.pushReplacement('/hod/dashboard',
          extra: {'email': email, 'full_name': fullName, 'role': 'HOD'});
      break;
    case UserRole.staff:
      context.pushReplacement('/staff/dashboard',
          extra: {'email': email, 'full_name': fullName, 'role': 'STAFF'});
      break;
    case UserRole.vendor:
      context.pushReplacement('/vendor/dashboard', extra: {
        'company_name': fullName,
        'email': email,
        'first_login': 0,
      });
      break;
    case UserRole.student:
    case UserRole.guest:
      context.pushReplacement('/complaint/fill', extra: {
        'nama_user': fullName,
        'emel_user': email,
        'selected_dept': (department ?? 'IT').trim().toLowerCase(),
      });
      break;
  }
}

/// DEV ONLY — a row of chips letting you choose which role the Microsoft
/// button should log in as.
class DevRoleSwitcher extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  final List<UserRole> roles;

  const DevRoleSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
    this.roles = const [
      UserRole.student,
      UserRole.staff,
      UserRole.admin,
      UserRole.hod,
      UserRole.vendor,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'DEV LOGIN — pick a role, then tap Microsoft',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: roles.map((role) {
            final bool isSelected = role == selected;
            return ChoiceChip(
              label: Text(
                role.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.navy,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(role),
              selectedColor: AppColors.navy,
              backgroundColor: AppColors.navy.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
