# RUSH — UniKL RCMP User Helpdesk

RUSH is a Flutter mobile/web client for an internal helpdesk and complaint-ticketing system for **UniKL RCMP** (Universiti Kuala Lumpur, Royal College of Medicine Perak). Users file complaints/tickets against a department (IT, Administration & Facilities, or Maintenance), and the ticket flows through staff, department admins, vendors, and heads of department until it's resolved.

> "RUSH" is a branded acronym for "RCMP User Helpdesk" — this is **not** a delivery/logistics app.

## Contents

- [Tech stack](#tech-stack)
- [Architecture overview](#architecture-overview)
- [User roles & flows](#user-roles--flows)
- [Routes](#routes)
- [Project structure](#project-structure)
- [Backend / API](#backend--api)
- [Getting started](#getting-started)
- [Known issues & tech debt](#known-issues--tech-debt)

## Tech stack

- **Flutter / Dart** — Dart SDK `>=3.3.0 <4.0.0`
- **Navigation** — plain `Navigator` with an `onGenerateRoute` switch in `lib/main.dart` (no router package)
- **State** — no state-management package (Provider/Riverpod/Bloc); state is held in a singleton (`UserSession`) and a few global variables in `main.dart`
- **Backend** — a custom **PHP/MySQL API** served locally via Laragon during development
- **Auth** — `aad_oauth` for Microsoft/Azure AD SSO (staff, students, operators); vendors use email/password against the PHP backend
- Other notable packages: `http` (REST calls), `shared_preferences`, `image_picker`, `file_picker`, `flutter_local_notifications`, `url_launcher`

## Architecture overview

There is no API client/service abstraction layer or models layer. Each screen:

1. Builds its own request URL (pointing at the PHP backend, see [Backend / API](#backend--api))
2. Calls `http.get`/`http.post` directly
3. Parses the raw JSON response inline and builds UI state from it

The only shared, cross-cutting pieces are:

- `lib/services/user_session.dart` — a singleton holding the logged-in user's `name`/`email`
- `lib/services/notification_service.dart` — wraps `flutter_local_notifications` for local push-style notifications
- `lib/theme/app_theme.dart` — `AppColors` (navy/gold palette) and the shared `PortalTopBar` app bar widget
- `lib/theme/admin_theme.dart` — theme extensions for admin screens

`lib/main.dart` also declares a few **global variables** used as a lightweight dev/test session mechanism (see [Known issues](#known-issues--tech-debt)).

## User roles & flows

| Role | Entry screen | Purpose |
|---|---|---|
| **End user** (student/staff) | `UserLoginScreen` (Microsoft SSO) → `HelpdeskHomeScreen` | Picks a department, files a complaint/ticket, tracks "My Submissions" |
| **Operator** | `OperatorPortalScreen` | Triages incoming tickets (Microsoft SSO with fallback login) |
| **Department Staff** | `StaffDashboardScreen` | Works on tickets assigned to their department |
| **Department Admin** | `AdminDashboardScreen` | Manages staff, vendors, ticket categories, and views reports for their department |
| **Vendor** | `VendorPortalScreen` (email/password) → `VendorDashboardScreen` | External contractors handling work orders assigned to them; manage their own company staff |
| **Head of Department (HOD)** | `HodDashboardScreen` | Oversight dashboards and reports |

**Complaint flow (end user):** `HelpdeskHomeScreen` → select department → `UserLoginScreen` → `DashboardScreen` → `ComplaintFillDetailsScreen` → `ComplaintPreviewReviewScreen` → `ComplaintConfirmSubmissionsScreen` → `ComplaintSubmittedScreen`, then trackable via `MySubmissionsScreen` / `TicketDetailUserScreen`.

## Routes

Defined in `lib/main.dart` via `onGenerateRoute`:

| Route | Screen |
|---|---|
| `/` | `HelpdeskHomeScreen` — department picker |
| `/login` | `UserLoginScreen` (takes department as route argument) |
| `/vendor` | `VendorPortalScreen` |
| `/operator` | `OperatorPortalScreen` |
| `/dashboard` | `DashboardScreen` |
| `/complaint/fill` | `ComplaintFillDetailsScreen` |
| `/complaint/preview` | `ComplaintPreviewReviewScreen` |
| `/complaint/confirm` | `ComplaintConfirmSubmissionsScreen` |
| `/complaint/submitted` | `ComplaintSubmittedScreen` |
| `/my-submissions` | `MySubmissionsScreen` |
| `/tickets/user-detail` | `TicketDetailUserScreen` |
| `/admin/dashboard` | `AdminDashboardScreen` |
| `/admin/tickets` | `AdminAllTicketsScreen` |
| `/admin/users` | `AdminManageUsersScreen` |
| `/admin/vendors` | `AdminManageUsersScreen` *(same screen as `/admin/users` — likely meant to be a separate vendor-management screen, see [Known issues](#known-issues--tech-debt))* |
| `/admin/categories` | `AdminCategoriesScreen` |
| `/admin/reports` | `AdminReportsScreen` |
| `/vendor/dashboard` | `VendorDashboardScreen` |
| `/vendor_ticket_workspace` | `VendorTicketWorkspaceScreen` |
| `/hod/dashboard` | `HodDashboardScreen` |
| `/hod/reports` | `HodReportsScreen` |
| `/staff/dashboard` | `StaffDashboardScreen` |
| `/staff/tickets` | `StaffAllTicketsScreen` |
| `/tickets/workspace` | `TicketWorkspaceScreen` (shared by admin and staff) |

The doc comment above `RushApp` in `main.dart` also references `/staff/login`, `/tickets/history`, and `/tickets/feedback`, but these are not currently implemented in the route table — treat them as planned/future routes.

## Project structure

```
lib/
├── main.dart                   # Entry point, global session vars, route table
├── assets/images/              # Logo, background images
├── theme/
│   ├── app_theme.dart          # AppColors, PortalTopBar
│   └── admin_theme.dart        # Admin-specific theme
├── services/
│   ├── user_session.dart       # Singleton: logged-in user name/email
│   └── notification_service.dart
└── screens/
    ├── helpdesk_home_screen.dart
    ├── user_login_screen.dart
    ├── vendor_portal_screen.dart
    ├── operator_portal_screen.dart
    ├── complaint/               # End-user ticket submission flow
    ├── dept/                    # Department staff flow
    ├── dept_admin/              # Department admin flow (staff/vendor/category/report mgmt)
    ├── hod/                     # Head of Department flow
    └── vendor/                  # Vendor company flow
```

There are no `models/`, `providers/`, or shared `widgets/` directories — data is handled as raw `Map`/`List` from JSON, and most widgets are defined inline per screen.

## Backend / API

The app talks to a PHP/MySQL backend (database name `unicomplaint`), typically run locally via **Laragon**. The base URL is hardcoded per-screen based on platform:

```dart
final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
final url = Uri.parse('http://$domain/helpdesk_api/get_my_complaints.php?email=...');
```

This pattern is repeated across many screens — there is no central API client or config file, so the backend host (`10.103.19.67`) is specific to the original developer's local network and **must be updated** for other environments (see [Known issues](#known-issues--tech-debt)).

Because the backend is `http://` (not `https://`), Android's `usesCleartextTraffic="true"` is set in the manifest.

### Known endpoints (`helpdesk_api/*.php`)

Auth / users: `check_user_role.php`, `get_microsoft_config.php`, `get_user.php`, `vendor_login.php`
Staff: `get_all_staff.php`, `add_staff.php`, `edit_staff.php`, `delete_staff.php`, `get_staff_members.php`, `get_staff_dashboard.php`
Vendors: `get_vendors.php`, `get_active_vendors_dropdown.php`, `add_vendor.php`, `delete_vendor.php`, `get_vendor_staff.php`, `add_vendor_staff.php`, `edit_vendor_staff.php`, `delete_vendor_staff.php`, `update_vendor_profile.php`, `update_vendor_action.php`, `get_vendor_tickets.php`
Tickets / complaints: `get_my_complaints.php`, `get_my_submissions.php`, `save_tickets.php`, `update_ticket_status.php`, `get_ticket_history.php`, `get_sla_status.php`, `add_ticket_feedback.php`, `get_ticket_feedback.php`
Admin / reporting: `get_admin_dashboard.php`, `get_admin_tickets.php`, `get_categories.php`, `edit_category.php`, `delete_category.php`, `get_dropdowns.php`, `get_all_reports.php`

> The backend source itself is not part of this repository — this README documents the client's expectations of it.

## Getting started

### Prerequisites

- Flutter SDK (Dart `>=3.3.0 <4.0.0`)
- A running instance of the `helpdesk_api` PHP backend and its MySQL database (`unicomplaint`), e.g. via Laragon, reachable at the host configured in the screens you intend to test
- Azure AD app registration details if testing Microsoft SSO login (`aad_oauth`), served via `get_microsoft_config.php`

### Setup

```bash
flutter pub get
```

Before running on a physical device/emulator, update the hardcoded backend IP (search for `10.103.19.67` across `lib/screens/`) to point at your local backend's LAN IP. When running on `flutter run -d chrome` (web), the app uses `localhost` instead.

To switch which department/user session the app starts in during local testing, edit `currentLoggedInUserEmail` at the top of `lib/main.dart`.

### Run

```bash
flutter run
```

### Lint

```bash
flutter analyze
```

Lint rules come from `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`); `build/`, `android/`, and `web/` are excluded from analysis.

## Known issues & tech debt

- **No iOS support in this checkout** — there is no `ios/` directory; only Android and Flutter web are currently set up.
- **Hardcoded backend host** — `10.103.19.67` is sprinkled across dozens of screen files instead of living in one config/constants file. Extracting a single API base-URL constant (and ideally a shared API client) would remove a lot of duplication and make switching environments much easier.
- **Duplicated session state** — `UserSession` (`lib/services/user_session.dart`) and the global `currentLoggedInUserEmail` variable in `main.dart` both track "who's logged in" but aren't unified; be careful which one a given screen actually reads.
- **Default Android package name** — `android/app/build.gradle.kts` still uses the Flutter template `applicationId`/`namespace` (`com.example.rushapp`); should be renamed before any real release.
- **`/admin/vendors` route** — currently points at the same `AdminManageUsersScreen` as `/admin/users`; a dedicated vendor-management screen may have been intended.
- **Stale widget test** — `test/widget_test.dart` is the unmodified Flutter counter-app template; it imports `package:rushapp/main.dart` (the actual package name is `rush_app`) and references a `MyApp` class that doesn't exist (the app's root widget is `RushApp`). It will not compile as-is and needs to be rewritten or removed.
- **No models/DTOs** — API responses are consumed as raw `Map<String, dynamic>`/`List<dynamic>` throughout the UI layer rather than typed models, which makes refactors and null-safety harder to reason about.
- Several source comments are written in mixed Bahasa Malaysia/English — useful context if onboarding new contributors unfamiliar with the convention.
