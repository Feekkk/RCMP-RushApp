import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // For attaching physical image files
import 'package:image_picker/image_picker.dart'; // For camera photo capture
import '../../theme/app_theme.dart';
import '../../main.dart';

/// Interface 5: "Submit a Complaint" — Step 1: Fill Details.
class ComplaintFillDetailsScreen extends StatefulWidget {
  const ComplaintFillDetailsScreen({super.key});

  @override
  State<ComplaintFillDetailsScreen> createState() =>
      _ComplaintFillDetailsScreenState();
}

class _ComplaintFillDetailsScreenState
    extends State<ComplaintFillDetailsScreen> {
// Text field input data managers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

// Selected Department Tab Status (0 = IT, 1 = Maintenance, 2 = Admin)
  int _activeTab = 0;
  final List<String> _departmentsTabs = [
    'Information Technology',
    'Maintenance',
    'Admin & Facilities Mgmt'
  ];

// Dynamic lists fetched from Laragon database
  List<String> _listCategories = [];
  List<String> _listDepartments = [];

// Stores user dropdown choice values
  String? _selectedCategory;
  String? _selectedDepartment;

// Manages image attachment files
  String _namaGambarSelected = 'No file attached';
  PlatformFile? _attachedFile;

  bool _isLoading = true;

  // function: get login payload data and auto-rolling live tab
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      // get wrapped arguments 'selected_dept' sent from login screen
      final Object? args = ModalRoute.of(context)?.settings.arguments;

      if (args != null && args is Map<String, dynamic>) {
        String chosenDept =
            (args['selected_dept'] ?? 'it').toString().toLowerCase().trim();

        // 2. AUTO-SET DEPARTMENT VALUE ACCORDING TO USER TAP FROM HOME SCREEN!
        if (chosenDept == 'maintenance') {
          _activeTab = 1; // Auto-switch screen to Maintenance tab!
        } else if (chosenDept == 'administration & facilities' ||
            chosenDept == 'admin') {
          _activeTab = 2; // Auto-switch screen to Admin tab!
        } else {
          _activeTab = 0; // Remain on IT tab
        }

        // 3. AFTER SWITCHING TAB, FORCE FETCH NEW DROPDOWN DATA FROM LARAGON!
        _ambilDataDropdown(_departmentsTabs[_activeTab]);

        debugPrint(
            "TAB INDEX AUTO-LOCKED AT: $_activeTab FOR DEPARTMENT: $chosenDept");
      }
      _isInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

// Function to call Laragon API according to selected department using dynamic kIsWeb IP
  Future<void> _ambilDataDropdown(String namaJabatan) async {
    setState(() => _isLoading = true);

    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse(
        'http://$domain/helpdesk_api/get_dropdowns.php?department=$namaJabatan');

    try {
      final respon = await http.get(url);

      if (respon.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(respon.body);

        setState(() {
          _listCategories = List<String>.from(data['categories']);
          _listDepartments = List<String>.from(data['departments']);
          _selectedCategory =
              null; // Reset old category selection whenever tab changes
          _isLoading = false;
        });
      } else {
        debugPrint("Failed to load dropdown data. Status: ${respon.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Connection error to Laragon: $e");
      setState(() => _isLoading = false);
    }
  }

  // === DIALOG PILIHAN SUMBER GAMBAR (CAMERA / GALLERY) ===
  Future<void> _tampilPilihanSumberGambar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Attachment Source',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF2563EB)),
                  ),
                  title: const Text(
                    'Take Photo (Camera)',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Use device camera to snap a picture',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _tangkapGambarKamera();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: Color(0xFF16A34A)),
                  ),
                  title: const Text(
                    'Choose from Gallery / Files',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Select an existing image from your device',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pilihGambarFizikal();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // === TANGKAP GAMBAR GUNAKAN KAMERA PERANTI ===
  Future<void> _tangkapGambarKamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final size = await photo.length();
        setState(() {
          _attachedFile = PlatformFile(
            name: photo.name.isNotEmpty
                ? photo.name
                : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
            path: kIsWeb ? null : photo.path,
            size: size,
            bytes: bytes,
          );
          _namaGambarSelected = _attachedFile!.name;
        });
        debugPrint("Camera Photo Captured Successfully: $_namaGambarSelected");
      }
    } catch (e) {
      debugPrint("Error capturing camera photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open camera: $e')),
        );
      }
    }
  }

  // === ONE FUNCTION FOR ALL PLATFORMS (WEB + MOBILE) ===
  Future<void> _pilihGambarFizikal() async {
    try {
      // FilePicker automatically opens Chrome explorer if Web
      // opens Android file picker if running on Emulator
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          // System auto-get: if web it takes bytes, if mobile it takes physical path
          _attachedFile = result.files.first;
          _namaGambarSelected = result.files.first.name;
        });
        debugPrint("File Successfully Selected Live: $_namaGambarSelected");
      }
    } catch (e) {
      debugPrint("Universal File Picker Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file picker: $e')),
        );
      }
    }
  }

// gather data and navigate user to Preview & Review screen
  void _hantarKePreview() {
    String description = _descriptionController.text.trim();
    String phoneNumber = _phoneNumberController.text.trim();
    String category = _selectedCategory ?? '';
    String department = _selectedDepartment ?? '';

    if (category.isEmpty || description.isEmpty || department.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('SLA & policy — Please fill all required fields (*)!')),
      );
      return;
    }

    final Object? args = ModalRoute.of(context)?.settings.arguments;
    bool isAddAnother = false;
    List<dynamic> existingList = [];
    if (args != null && args is Map<String, dynamic>) {
      isAddAnother = args['isAddAnother'] ?? false;
      existingList = args['existing_list'] ?? [];
    }

    // SESSION SECURITY KEY: Get email from main.dart global variable
    String safeLiveEmail = currentLoggedInUserEmail ?? 'user@gmail.com';

    // Auto-generate first name based on email prefix
    String safeLiveName = safeLiveEmail.contains('@')
        ? safeLiveEmail
            .split('@')[0]
            .toUpperCase()
            .replaceAll('.', ' ')
            .replaceAll('_', ' ')
        : 'USER COMPLAINANT';

    Map<String, dynamic> dataBorangBaru = {
      'category': category,
      'description': description,
      'phone_number': phoneNumber,
      'department': department,

      // apply DYNAMIC: static data proof!
      'full_name': safeLiveName,
      'email': safeLiveEmail,

      'isAddAnother': isAddAnother,
      'existing_list': existingList,
      'attachment_path': _namaGambarSelected,

      'attachment_file_bytes':
          _attachedFile?.bytes, // For capturing in Chrome Web
      'attachment_file_path': kIsWeb ? null : _attachedFile?.path,
    };

    context.push('/complaint/preview',
      extra: dataBorangBaru,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: PortalTopBar(
        title: 'UNIKL RCMP',
        subtitle: 'Help Desk System',
        trailing: TextButton.icon(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.close, size: 14, color: AppColors.navy),
          label: const Text('Close',
              style: TextStyle(color: AppColors.navy, fontSize: 12)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: FlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === 3 BUTANG JABATAN DI BAHAGIAN ATAS CARD ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton(0, 'IT', Icons.computer),
                    _buildTabButton(1, 'Maintenance', Icons.build_outlined),
                    _buildTabButton(2, 'Admin', Icons.apartment),
                  ],
                ),
                const SizedBox(height: 18),

                const Text('Submit a Complaint',
                    style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(
                  'Fill the details and your assigned ${_departmentsTabs[_activeTab]} department will attend to your request.',
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                const StepTracker(currentStep: 1),
                const SizedBox(height: 22),
                const InfoBanner(
                  tone: BannerTone.success,
                  title:
                      'SLA & policy — your complaint will be acknowledged shortly',
                  subtitle:
                      'Open Mon–Fri, 8am–5pm  ·  Current average response: 24 hours',
                ),
                const SizedBox(height: 24),
                const SectionHeading(
                  title: 'Complaint Details',
                  subtitle: 'Provide details about the incident and procedure.',
                ),
                const SizedBox(height: 14),

                // Dropdown Category Dinamik (Auto-filter ikut tab jabatan aktif)
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(child: LinearProgressIndicator()),
                      )
                    : LabeledDropdown(
                        label: 'Category',
                        hint: 'Select Category',
                        required: true,
                        items: _listCategories,
                        value: _selectedCategory,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                      ),

                const SizedBox(height: 16),

                // Kotak Teks Input Description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Description', style: AppTextStyles.fieldLabel),
                        Text(' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe your issue here',
                        hintStyle:
                            TextStyle(color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.fieldBackground,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Attachment', style: AppTextStyles.fieldLabel),
                    const SizedBox(width: 6),
                    Text('(optional)',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),

                // === KOTAK pilih ATTACH gambar  ===
                InkWell(
                  onTap: _tampilPilihanSumberGambar,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            _attachedFile != null
                                ? Icons.image
                                : Icons.cloud_upload_outlined,
                            size: 20,
                            color: AppColors.navy),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _namaGambarSelected,
                            style: TextStyle(
                                fontSize: 13,
                                color: _attachedFile != null
                                    ? AppColors.navy
                                    : AppColors.textMuted,
                                fontWeight: _attachedFile != null
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const SectionHeading(title: 'Your Information'),
                const SizedBox(height: 14),

                // Kotak Teks Input Phone Number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phone Number', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+60 1X-XXXXXXX',
                        hintStyle:
                            TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.call_outlined,
                            size: 18, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.fieldBackground,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dropdown Department / Faculty
                LabeledDropdown(
                  label: 'My Department / Faculty',
                  hint: 'Select Department / Faculty',
                  required: true,
                  items: _listDepartments,
                  value: _selectedDepartment,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedDepartment = newValue;
                    });
                  },
                ),

                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      label: 'Cancel',
                      onPressed: () {
                        context.push('/dashboard');
                      },
                    ),
                    const SizedBox(width: 12),
                    SuccessButton(
                      label: 'Preview & Review',
                      icon: Icons.arrow_forward,
                      onPressed: _hantarKePreview,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fungsi  gaya visual reka bentuk 3 Butang Jabatan di Atas Kad
  Widget _buildTabButton(int index, String title, IconData icon) {
    bool isSelected = _activeTab == index;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _activeTab = index;
        });
        _ambilDataDropdown(_departmentsTabs[index]);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.navy : Colors.grey.shade100,
        foregroundColor: isSelected ? Colors.white : AppColors.textSecondary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
