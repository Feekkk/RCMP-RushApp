import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import 'add_staff_dialog.dart';
import 'edit_staff_dialog.dart';
import 'delete_staff_dialog.dart';
import 'add_vendor_dialog.dart';
import '../../main.dart';

const _adminNavItems = [
  AdminNavItem(Icons.dashboard_outlined, 'Dashboard', '/admin/dashboard'),
  AdminNavItem(Icons.confirmation_number_outlined, 'Tickets', '/admin/tickets'),
  AdminNavItem(Icons.people_outline, 'Users', '/admin/users'),
  AdminNavItem(Icons.category_outlined, 'Categories', '/admin/categories'),
  AdminNavItem(Icons.bar_chart_outlined, 'Reports', '/admin/reports'),
];

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  int _activeTab = 0; // 0 = Staff, 1 = Vendor

  // Staff variables
  List<dynamic> _allStaffList = [];
  List<dynamic> _filteredStaffList = [];
  bool _isLoadingStaff = true;
  final TextEditingController _staffSearchController = TextEditingController();
  String _selectedRoleFilter = 'All Roles';
  final List<String> _roleOptions = ['All Roles', 'STAFF', 'ADMIN', 'HOD'];

  // Vendor variables
  List<dynamic> _senaraiSemuaVendors = [];
  List<dynamic> _senaraiVendorsDipaparkan = [];
  bool _isLoadingVendors = true;
  final TextEditingController _vendorSearchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  String _namaJabatanLive = "Loading Department...";

  @override
  void initState() {
    super.initState();
    _ambilSenaraiStaff();
    _tarikDataVendors();
    _staffSearchController.addListener(_jalankanTapisanStaff);
    _vendorSearchController.addListener(_jalankanTapisanVendor);
  }

  @override
  void dispose() {
    _staffSearchController.dispose();
    _vendorSearchController.dispose();
    super.dispose();
  }

  Future<void> _ambilSenaraiStaff() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_all_staff.php?email=$currentLoggedInUserEmail');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(respon.body);
        if (mounted) {
          setState(() {
            _namaJabatanLive =
                data['department_label'] ?? 'IT Department · Admin';
            _allStaffList = data['staff'] ?? [];
            _filteredStaffList = data['staff'] ?? [];
            _isLoadingStaff = false;
          });
          _jalankanTapisanStaff();
        }
      }
    } catch (e) {
      debugPrint("Ralat staff: $e");
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _tarikDataVendors() async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_vendors.php?email=$currentLoggedInUserEmail&department=${Uri.encodeComponent(_namaJabatanLive)}&b_cache=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        final List<dynamic> dataDiterima = json.decode(respon.body);
        if (mounted) {
          setState(() {
            _senaraiSemuaVendors = dataDiterima;
            _senaraiVendorsDipaparkan = dataDiterima;
            senaraiVendorGlobalJabatanSyafiqah = List.from(dataDiterima);
            _isLoadingVendors = false;
          });
          _jalankanTapisanVendor();
        }
      }
    } catch (e) {
      debugPrint("Ralat vendor: $e");
      if (mounted) setState(() => _isLoadingVendors = false);
    }
  }

  void _jalankanTapisanStaff() {
    String query = _staffSearchController.text.toLowerCase().trim();
    setState(() {
      _filteredStaffList = _allStaffList.where((staff) {
        String staffCode = (staff['staff_code'] ?? '').toString().toLowerCase();
        String fullName = (staff['full_name'] ?? '').toString().toLowerCase();
        String email = (staff['email'] ?? '').toString().toLowerCase();
        String roleName = (staff['role'] ?? 'Staff').toString().toUpperCase();

        bool matchesSearch = fullName.contains(query) ||
            email.contains(query) ||
            staffCode.contains(query);
        bool matchesRole = _selectedRoleFilter == 'All Roles' ||
            roleName == _selectedRoleFilter;

        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _jalankanTapisanVendor() {
    String kataKunci = _vendorSearchController.text.trim().toLowerCase();
    setState(() {
      _senaraiVendorsDipaparkan = _senaraiSemuaVendors.where((vendor) {
        bool matchSearch = (vendor['company_name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(kataKunci) ||
            (vendor['email'] ?? '')
                .toString()
                .toLowerCase()
                .contains(kataKunci) ||
            (vendor['phone'] ?? '').toString().contains(kataKunci);

        String statusSyarikatRaw =
            (vendor['status'] ?? 'active').toString().toLowerCase().trim();
        bool matchStatusCard = true;

        if (_selectedStatusFilter == 'Pending') {
          matchStatusCard = (statusSyarikatRaw == 'pending');
        } else if (_selectedStatusFilter == 'Active') {
          matchStatusCard = (statusSyarikatRaw == 'active' ||
              statusSyarikatRaw == 'approved');
        } else if (_selectedStatusFilter == 'Suspended') {
          matchStatusCard = (statusSyarikatRaw == 'suspended' ||
              statusSyarikatRaw == 'inactive');
        }

        return matchSearch && matchStatusCard;
      }).toList();
    });
  }

  Future _eksekusiUpdateVendorKeLaragon({
    required String id,
    required String company,
    required String addr,
    required String cty,
    required String stt,
    required String post,
    required String phn,
    required String statusText,
    required String password,
    required String pName,
    required String pPos,
    required String pPhn,
  }) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url =
        Uri.parse('http://$domain/helpdesk_api/update_vendor_profile.php');
    try {
      final respon = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "vendor_id": id,
            "company_name": company,
            "address": addr,
            "city": cty,
            "state": stt,
            "postcode": post,
            "phone": phn,
            "status": statusText,
            "new_password": password,
            "pic_name": pName,
            "pic_position": pPos,
            "pic_phone": pPhn
          }));
      if (respon.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vendor updated successfully!')));
        }
        _tarikDataVendors();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future _eksekusiPadamVendorDariLaragon(String id, String nama) async {
    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/delete_vendor.php?vendor_id=$id');
    try {
      final respon = await http.get(url);
      if (respon.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$nama removed.')));
        }
        _tarikDataVendors();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _pamerDialogEditVendor(Map<String, dynamic> vendorSemasa) {
    final companyNameCtrl =
        TextEditingController(text: vendorSemasa['company_name']);
    final addressCtrl =
        TextEditingController(text: vendorSemasa['address'] ?? '');
    final cityCtrl = TextEditingController(text: vendorSemasa['city'] ?? '');
    final stateCtrl = TextEditingController(text: vendorSemasa['state'] ?? '');
    final postcodeCtrl =
        TextEditingController(text: vendorSemasa['postcode'] ?? '');
    final phoneCtrl = TextEditingController(text: vendorSemasa['phone'] ?? '');
    final picNameCtrl =
        TextEditingController(text: vendorSemasa['pic_name'] ?? '');
    final picPositionCtrl =
        TextEditingController(text: vendorSemasa['pic_position'] ?? '');
    final picPhoneCtrl =
        TextEditingController(text: vendorSemasa['pic_phone'] ?? '');
    final newPasswordCtrl = TextEditingController();
    String statusSemasaLive =
        (vendorSemasa['status'] ?? 'active').toString().toLowerCase() ==
                'suspended'
            ? 'Suspended'
            : 'Active';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 420, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded,
                              color: AppColors.navy, size: 22),
                          const SizedBox(width: 6),
                          const Expanded(
                              child: Text('Edit Vendor Profile',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary))),
                          IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppColors.textMuted),
                              onPressed: () => Navigator.pop(dialogContext)),
                        ],
                      ),
                      const Divider(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSafeEditField(
                                  label: 'Company Name',
                                  ctrl: companyNameCtrl,
                                  icon: Icons.storefront_outlined),
                              const SizedBox(height: 12),
                              _buildSafeEditField(
                                  label: 'Address',
                                  ctrl: addressCtrl,
                                  icon: Icons.location_on_outlined),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildSafeEditField(
                                          label: 'City',
                                          ctrl: cityCtrl,
                                          icon: Icons.location_city_outlined)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildSafeEditField(
                                          label: 'State',
                                          ctrl: stateCtrl,
                                          icon: Icons.map_outlined)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildSafeEditField(
                                          label: 'Postcode',
                                          ctrl: postcodeCtrl,
                                          icon:
                                              Icons.markunread_mailbox_outlined,
                                          type: TextInputType.number)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildSafeEditField(
                                          label: 'Phone *',
                                          ctrl: phoneCtrl,
                                          icon: Icons.call_outlined,
                                          type: TextInputType.phone)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildSafeEditField(
                                  label: 'New Password (Optional)',
                                  ctrl: newPasswordCtrl,
                                  icon: Icons.lock_reset_outlined,
                                  obscure: true),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text("Account Status:",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 14),
                                  ChoiceChip(
                                    label: const Text('Active',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    selected: statusSemasaLive == 'Active',
                                    selectedColor: const Color(0xFFEAF7EE),
                                    onSelected: (bool selected) {
                                      if (selected) {
                                        setDialogState(
                                            () => statusSemasaLive = 'Active');
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Suspended',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    selected: statusSemasaLive == 'Suspended',
                                    selectedColor: const Color(0xFFFFECE5),
                                    onSelected: (bool selected) {
                                      if (selected) {
                                        setDialogState(() =>
                                            statusSemasaLive = 'Suspended');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.grey))),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _eksekusiUpdateVendorKeLaragon(
                                id: vendorSemasa['vendor_id'].toString(),
                                company: companyNameCtrl.text.trim(),
                                addr: addressCtrl.text.trim(),
                                cty: cityCtrl.text.trim(),
                                stt: stateCtrl.text.trim(),
                                post: postcodeCtrl.text.trim(),
                                phn: phoneCtrl.text.trim(),
                                statusText: statusSemasaLive == 'Active'
                                    ? 'active'
                                    : 'suspended',
                                password: newPasswordCtrl.text.trim(),
                                pName: picNameCtrl.text.trim(),
                                pPos: picPositionCtrl.text.trim(),
                                pPhn: picPhoneCtrl.text.trim(),
                              );
                            },
                            child: const Text('Save Changes',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _pamerKonfirmasiHapusVendor(String idVendor, String namaSyarikat) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.delete_forever,
                      color: Color(0xFFD64545), size: 22),
                  const SizedBox(width: 8),
                  const Text('Delete Vendor Company',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD64545))),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  children: [
                    const TextSpan(text: 'Delete vendor company '),
                    TextSpan(
                        text: namaSyarikat,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD64545))),
                    const TextSpan(text: '?\n\nThis action is '),
                    const TextSpan(
                        text: 'permanent',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(
                        text:
                            ' and cannot be undone. The vendor and all associated data will be completely removed from the unicomplaint help desk system.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade100)),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Make sure all assigned work orders are reassigned before deleting.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey))),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD64545),
                        foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _eksekusiPadamVendorDariLaragon(idVendor, namaSyarikat);
                    },
                    child: const Text('Yes, Delete Vendor',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafeEditField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      bottomNavigationBar: PortalBottomNav(
        items: _adminNavItems,
        currentRoute: '/admin/users',
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
            const Text('User Management',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoadingStaff || _isLoadingVendors
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await _ambilSenaraiStaff();
                  await _tarikDataVendors();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ==================== HEADER ROW: SEGMENTED PILL TABS & ADD BUTTON ====================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Segmented Pill Container
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Staff Tab
                              GestureDetector(
                                onTap: () => setState(() => _activeTab = 0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 0
                                        ? AppColors.navy
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 15,
                                        color: _activeTab == 0
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Staff (${_allStaffList.length})',
                                        style: TextStyle(
                                          color: _activeTab == 0
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Vendor Tab
                              GestureDetector(
                                onTap: () => setState(() => _activeTab = 1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 1
                                        ? AppColors.navy
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.storefront_outlined,
                                        size: 15,
                                        color: _activeTab == 1
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Vendor (${_senaraiSemuaVendors.length})',
                                        style: TextStyle(
                                          color: _activeTab == 1
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Right: Add New User Dropdown Button
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'staff') {
                              await showAddStaffDialog(context);
                              _ambilSenaraiStaff();
                            } else if (value == 'vendor') {
                              await showAddVendorDialog(
                                context,
                                department: _namaJabatanLive,
                              );
                              _tarikDataVendors();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'staff',
                              child: Row(
                                children: [
                                  Icon(Icons.person_add_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Add Staff'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'vendor',
                              child: Row(
                                children: [
                                  Icon(Icons.storefront_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Add Vendor'),
                                ],
                              ),
                            ),
                          ],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          color: Colors.white,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add, size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text('New User',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(width: 6),
                                Icon(Icons.keyboard_arrow_down,
                                    size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ==================== TAB CONTENT ====================
                    if (_activeTab == 0) ...[
                      // STAFF TAB CONTENT
                      Column(
                        children: [
                          TextField(
                            controller: _staffSearchController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Search staff name, email, code...',
                              prefixIcon: const Icon(Icons.search,
                                  size: 18, color: AppColors.textSecondary),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: const BorderSide(
                                      color: AppColors.border)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Sort by Role:',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedRoleFilter,
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                      filled: true,
                                      fillColor: AppColors.fieldBackground,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                              color: AppColors.border)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                              color: AppColors.border)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                              color: AppColors.navy,
                                              width: 1.5)),
                                    ),
                                    items: _roleOptions.map((role) {
                                      return DropdownMenuItem<String>(
                                        value: role,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 8),
                                          child: Text(
                                            role,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedRoleFilter = newValue;
                                        });
                                        _jalankanTapisanStaff();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      if (_filteredStaffList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                              child: Text('No matching staff record found.',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13))),
                        ),

                      ..._filteredStaffList.map((staff) {
                        String staffCodeVal =
                            (staff['staff_code'] ?? '').toString();
                        String fullName = staff['full_name'] ?? 'No Name';
                        String email = staff['email'] ?? 'No Email';
                        String phone =
                            (staff['phone'] == null || staff['phone'] == '')
                                ? '—'
                                : staff['phone'];
                        String dbStatus = (staff['status'] ?? 'active')
                            .toString()
                            .toLowerCase();
                        String roleName =
                            (staff['role'] ?? 'Staff').toString().toUpperCase();
                        String categoryMentah =
                            (staff['category'] ?? '-').toString().trim();
                        String category = categoryMentah;

                        if (roleName == 'ADMIN') {
                          category = '-';
                        } else if (categoryMentah.contains('/')) {
                          category = categoryMentah.split('/').last.trim();
                        }
                        if (category.isEmpty ||
                            category.toLowerCase() == 'null') {
                          category = '-';
                        }

                        String passHash =
                            staff['password_hash'] ?? 'password123';
                        bool isActive = dbStatus == 'active';
                        String statusLabel = isActive ? 'ACTIVE' : 'INACTIVE';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: DataRowCard(
                            title: fullName.toUpperCase(),
                            subtitle: email,
                            fields: [
                              MapEntry('Staff Code', staffCodeVal),
                              MapEntry('Phone', phone),
                              MapEntry('Role', roleName),
                              MapEntry('Category', category),
                            ],
                            trailingTag: StatusTag(
                                label: statusLabel,
                                background: isActive
                                    ? const Color(0xFFEAF7EE)
                                    : const Color(0xFFFDF2F2),
                                foreground: isActive
                                    ? const Color(0xFF2E9E52)
                                    : const Color(0xFFD64545)),
                            actions: [
                              IconTextAction(
                                  icon: Icons.edit_outlined,
                                  label: 'Edit',
                                  onTap: () async {
                                    String actualStaffCode =
                                        (staff['staff_code'] ??
                                                staff['staff_id'] ??
                                                '')
                                            .toString();
                                    if (actualStaffCode.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Error: This staff row does not contain a valid Staff Code!')),
                                      );
                                      return;
                                    }
                                    await showEditStaffDialog(
                                      context,
                                      staffName: fullName,
                                      staffCode: actualStaffCode,
                                      email: email,
                                      phone: phone,
                                      password: passHash,
                                      status: dbStatus,
                                      category: category,
                                    );
                                    _ambilSenaraiStaff();
                                  }),
                              IconTextAction(
                                icon: Icons.delete_outline,
                                label: 'Remove',
                                color: const Color(0xFFD64545),
                                onTap: () async {
                                  await showDeleteStaffDialog(context,
                                      staffName: fullName,
                                      staffCode: staffCodeVal);
                                  _ambilSenaraiStaff();
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      // VENDOR TAB CONTENT
                      TextField(
                        controller: _vendorSearchController,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Search vendor company, email, phone...',
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: AppColors.textSecondary),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_senaraiVendorsDipaparkan.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                              child: Text('No vendor companies found.',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13))),
                        ),

                      ..._senaraiVendorsDipaparkan.map((vendor) {
                        String idVendor = vendor['vendor_id'].toString();
                        String companyName =
                            vendor['company_name'] ?? 'Vendor Company';
                        String email = vendor['email'] ?? 'No Email';
                        String phone = vendor['phone'] ?? '—';
                        String regDate = vendor['created_at'] ??
                            vendor['registered_at'] ??
                            '—';
                        if (regDate.length >= 10) {
                          regDate = regDate.substring(0, 10);
                        }
                        String statusVal =
                            (vendor['status'] ?? 'active').toString();
                        bool isActive = statusVal.toLowerCase() == 'active' ||
                            statusVal.toLowerCase() == 'approved';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: DataRowCard(
                            title: companyName.toUpperCase(),
                            subtitle: email,
                            fields: [
                              MapEntry('Phone', phone),
                              MapEntry('Registered', regDate),
                            ],
                            trailingTag: StatusTag(
                                label: statusVal.toUpperCase(),
                                background: isActive
                                    ? const Color(0xFFEAF7EE)
                                    : const Color(0xFFFDF2F2),
                                foreground: isActive
                                    ? const Color(0xFF2E9E52)
                                    : const Color(0xFFD64545)),
                            actions: [
                              IconTextAction(
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                onTap: () => _pamerDialogEditVendor(vendor),
                              ),
                              IconTextAction(
                                icon: Icons.delete_outline,
                                label: 'Remove',
                                color: const Color(0xFFD64545),
                                onTap: () => _pamerKonfirmasiHapusVendor(
                                    idVendor, companyName),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
