import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../main.dart';

const _adminNavItems = [
  AdminNavItem(Icons.dashboard_outlined, 'Dashboard', '/admin/dashboard'),
  AdminNavItem(Icons.confirmation_number_outlined, 'Tickets', '/admin/tickets'),
  AdminNavItem(Icons.people_outline, 'Users', '/admin/users'),
  AdminNavItem(Icons.category_outlined, 'Categories', '/admin/categories'),
  AdminNavItem(Icons.bar_chart_outlined, 'Reports', '/admin/reports'),
];

class AdminAllTicketsScreen extends StatefulWidget {
  const AdminAllTicketsScreen({super.key});

  @override
  State<AdminAllTicketsScreen> createState() => _AdminAllTicketsScreenState();
}

class _AdminAllTicketsScreenState extends State<AdminAllTicketsScreen> {
  bool _isLoading = true;
  List<dynamic> _allTickets = [];
  List<dynamic> _filteredTickets = [];

  String _namaJabatanLive = "Loading Department...";

// Counter Map Elements
  Map<String, String> _counters = {
    "all": "0",
    "open": "0",
    "in_progress": "0",
    "closed": "0"
  };

// SEARCH & FILTER CONTROLLER
  final TextEditingController _searchController = TextEditingController();
  String _activeStatusTab = 'All'; // Track current active stat mini card filter
  String _selectedPriority = 'All Priorities';
  String _selectedCategory = 'All Categories';

  final List<String> _priorityOptions = [
    'All Priorities',
    'Low',
    'Medium',
    'High'
  ];
  List<String> _categoryOptions = ['All Categories'];

  @override
  void initState() {
    super.initState();
    _ambilSenaraiTiketAdmin();
    _loadCategoriesDropdown();
    _searchController.addListener(_tapisSenaraiTiketDinamik);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ambilSenaraiTiketAdmin() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_admin_tickets.php?email=$currentLoggedInUserEmail');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _namaJabatanLive =
              data['department_label'] ?? 'IT Department · Admin';
          _allTickets = data['tickets'] ?? [];
          _counters = Map<String, String>.from(data['counters']);
          _isLoading = false;
        });
        _tapisSenaraiTiketDinamik();
      }
    } catch (e) {
      print("Error linking to admin tickets pool: $e");
      setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  // DROPDOWN FILTER JABATAN: apply email SESI LOGIN REAL-TIME
  // =========================================================================
  Future<void> _loadCategoriesDropdown() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';

    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_dropdowns.php?email=$currentLoggedInUserEmail&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<String> fetchedCats =
            List<String>.from(data['categories'] ?? []);
        setState(() {
          _categoryOptions = ['All Categories', ...fetchedCats];
        });
        print(
            "DROPDOWN CATEGORIES LIVE SYNCED: ${_categoryOptions.length} items loaded for $currentLoggedInUserEmail");
      }
    } catch (e) {
      print("Dropdown category pull fail: $e");
    }
  }

// INTERACTIVE LIVE FILTER MATRIX LOGIC
  void _tapisSenaraiTiketDinamik() {
    String query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredTickets = _allTickets.where((ticket) {
        String ticketId = (ticket['ticket_id'] ?? '').toString().toLowerCase();
        String title = (ticket['title'] ?? '').toString().toLowerCase();
        String priority =
            (ticket['priority'] ?? 'Medium').toString().toLowerCase();
        String category = (ticket['category'] ?? ticket['title'] ?? '')
            .toString()
            .toLowerCase();
        String status = (ticket['status'] ?? 'open').toString().toLowerCase();

// 1. Verify Stat Card Status Selection Tab
        bool matchesStatus = _activeStatusTab == 'All' ||
            (_activeStatusTab == 'Open' && status == 'open') ||
            (_activeStatusTab == 'In Progress' && status == 'in_progress') ||
            (_activeStatusTab == 'Closed' && status == 'closed');

// 2. Verify Search Bar Query
        bool matchesSearch = ticketId.contains(query) || title.contains(query);

// 3. Verify Priority Dropdown State
        bool matchesPriority = _selectedPriority == 'All Priorities' ||
            priority == _selectedPriority.toLowerCase();

// 4. Verify Categories Dropdown Track
        bool matchesCategory = _selectedCategory == 'All Categories' ||
            category.contains(_selectedCategory.toLowerCase());

        return matchesStatus &&
            matchesSearch &&
            matchesPriority &&
            matchesCategory;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'closed') return const Color(0xFF2E9E52);
    if (status.toLowerCase() == 'in_progress') return const Color(0xFFC9A227);
    return const Color(0xFFD64545);
  }

  Color _getStatusBg(String status) {
    if (status.toLowerCase() == 'closed') return const Color(0xFFEAF7EE);
    if (status.toLowerCase() == 'in_progress') return const Color(0xFFFFF8E6);
    return const Color(0xFFFDF2F2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      bottomNavigationBar: PortalBottomNav(
        items: _adminNavItems,
        currentRoute: '/admin/tickets',
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(1),
          child: Image.asset(
            'lib/assets/images/unikl_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shield, color: AppColors.navy),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_namaJabatanLive,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const Text('All Tickets Management',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _ambilSenaraiTiketAdmin,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _activeStatusTab = 'All';
                              _tapisSenaraiTiketDinamik();
                            }),
                            child: StatMiniCard(
                              value: _counters['all']!,
                              label: 'All',
                              icon: Icons.confirmation_number_outlined,
                              selected: _activeStatusTab == 'All',
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _activeStatusTab = 'Open';
                              _tapisSenaraiTiketDinamik();
                            }),
                            child: StatMiniCard(
                              value: _counters['open']!,
                              label: 'Open',
                              icon: Icons.mark_email_unread_outlined,
                              selected: _activeStatusTab == 'Open',
                              color: const Color(0xFFD64545),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _activeStatusTab = 'In Progress';
                              _tapisSenaraiTiketDinamik();
                            }),
                            child: StatMiniCard(
                              value: _counters['in_progress']!,
                              label: 'Progress',
                              icon: Icons.autorenew,
                              selected: _activeStatusTab == 'In Progress',
                              color: const Color(0xFFC9A227),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _activeStatusTab = 'Closed';
                              _tapisSenaraiTiketDinamik();
                            }),
                            child: StatMiniCard(
                              value: _counters['closed']!,
                              label: 'Closed',
                              icon: Icons.check_circle_outline,
                              selected: _activeStatusTab == 'Closed',
                              color: const Color(0xFF2E9E52),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

// Integrated Search & Dropdown Filter Layout Panel
                    Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'Search ticket ID or title...',
                            prefixIcon: const Icon(Icons.search,
                                size: 18, color: AppColors.textSecondary),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide:
                                    const BorderSide(color: AppColors.border)),
                            filled: true,
                            fillColor: AppColors.pageBackground,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Priority Dropdown Filter
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: DropdownButtonFormField(
                                  value: _selectedPriority,
                                  isExpanded: true,
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: AppColors.textMuted),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    filled: true,
                                    fillColor: AppColors.fieldBackground,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                            color: AppColors.border)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                            color: AppColors.border)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                            color: AppColors.navy, width: 1.5)),
                                  ),
                                  items: _priorityOptions
                                      .map((v) => DropdownMenuItem(
                                            value: v,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 8),
                                              child: Text(
                                                v,
                                                style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedPriority = v);
                                      _tapisSenaraiTiketDinamik();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Category Dropdown Filter
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _selectedCategory,
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: AppColors.textMuted),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    filled: true,
                                    fillColor: AppColors.fieldBackground,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                            color: AppColors.border)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                            color: AppColors.border)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                            color: AppColors.navy, width: 1.5)),
                                  ),
                                  items: _categoryOptions.map((v) {
                                    return DropdownMenuItem<String>(
                                        value: v,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 8),
                                          child: Text(
                                            v,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary),
                                          ),
                                        ));
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedCategory = v);
                                      _tapisSenaraiTiketDinamik();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Showing ${_filteredTickets.length} results',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (_filteredTickets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                            child: Text(
                                'No complaints match your active filter tracks.',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 13))),
                      ),
// === LIVE FILTERED TICKETS LOOP GENERATOR ===
                    ..._filteredTickets.map((ticket) {
                      String idVal = ticket['ticket_id'] ?? '';
                      //String titleVal  = ticket['title'] ?? 'General Issue';
                      String emailVal =
                          ticket['submitter_email'] ?? 'No Submitter Email';
                      String deptVal =
                          ticket['my_department'] ?? 'General Support';
                      String catVal =
                          ticket['category'] ?? ticket['title'] ?? 'General';
                      String prioRaw = ticket['priority'] ?? 'Medium';
                      String statusRaw = ticket['status'] ?? 'open';

                      String tajukAsal = ticket['title'] ?? 'General Issue';
                      String namaStaffRemark =
                          (ticket['remarks'] ?? '').toString().trim();

                      String formattedPrio =
                          prioRaw.substring(0, 1).toUpperCase() +
                              prioRaw.substring(1).toLowerCase();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TicketCard(
                          ticketId: idVal,
                          title: tajukAsal,
                          submittedBy: emailVal,
                          department: deptVal,
                          category: catVal,
                          priority: formattedPrio,
                          status: statusRaw.toUpperCase().replaceAll('_', ' '),
                          statusColor: _getStatusColor(statusRaw),
                          statusBg: _getStatusBg(statusRaw),
                          assignedStaff: namaStaffRemark,
                          onView: () async {
                            // Pass the entire record packet down to workspace dynamically
                            final refresh = await context.push('/tickets/workspace',
                                extra: ticket);
                            if (refresh == true) _ambilSenaraiTiketAdmin();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }
}
