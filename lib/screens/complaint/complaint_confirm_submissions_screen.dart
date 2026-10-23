import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'add_another_item_dialog.dart'; // Original file dialog
import '../../main.dart';

/// Interface 7: "Confirm All Submissions" screen.
class ComplaintConfirmSubmissionsScreen extends StatefulWidget {
  const ComplaintConfirmSubmissionsScreen({super.key});

  @override
  State<ComplaintConfirmSubmissionsScreen> createState() =>
      _ComplaintConfirmSubmissionsScreenState();
}

class _ComplaintConfirmSubmissionsScreenState
    extends State<ComplaintConfirmSubmissionsScreen> {
  List<Map<String, dynamic>> _senaraiAduan = [];
  bool _isInitialized = false;
  bool _isSending = false;

// =========================================================================
// DYNAMIC SESSION KEY:
// System reads dynamic session email and name from main.dart!
// =========================================================================
  String get _safeLiveEmail => currentLoggedInUserEmail ?? "user@gmail.com";

  String get _safeLiveName => _safeLiveEmail.contains('@')
      ? _safeLiveEmail
          .split('@')[0]
          .toUpperCase()
          .replaceAll('.', ' ')
          .replaceAll('_', ' ')
      : "USER COMPLAINANT";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        if (args is List) {
          _senaraiAduan = args.map((item) {
            Map<String, dynamic> dataAduan = Map<String, dynamic>.from(item);
            dataAduan['email'] = dataAduan['email'] ?? _safeLiveEmail;
            dataAduan['full_name'] = dataAduan['full_name'] ?? _safeLiveName;
            return dataAduan;
          }).toList();
        } else if (args is Map<String, dynamic>) {
          Map<String, dynamic> dataAduan = Map<String, dynamic>.from(args);
          dataAduan['email'] = _safeLiveEmail;
          dataAduan['full_name'] = _safeLiveName;
          _senaraiAduan.add(dataAduan);
        }
      }
      _isInitialized = true;
    }
  }

  void _tampilDialogPadam(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.navy)),
          content: const Text(
              'Are you sure you want to delete this complaint? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Keep Item', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _senaraiAduan.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Complaint item removed successfully.')),
                );
              },
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _bukaDialogAddAnother() {
    showAddAnotherItemDialog(context, existingList: _senaraiAduan);
  }

  // =========================================================================
  // MULTIPART FILE UPLOADER ENGINE
  // Sending physical image files into the uploads folder
  // =========================================================================
  Future<void> _simpanSemuaAduanKeDatabase() async {
    if (_senaraiAduan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Your submission list is empty. Please add a complaint.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final String domain = kIsWeb ? 'localhost' : '10.103.19.67';
    final url = Uri.parse('http://$domain/helpdesk_api/save_tickets.php');

    try {
      // STEP 1: Build http.MultipartRequest!
      var requestMultipart = http.MultipartRequest('POST', url);

      // apply email data and live session name
      final listHantaranTulen = _senaraiAduan.map((aduan) {
        aduan['email'] = _safeLiveEmail;
        aduan['full_name'] = _safeLiveName;
        return aduan;
      }).toList();

      // Feed complaint list text array data as string field
      requestMultipart.fields['aduan_json_data'] =
          json.encode(listHantaranTulen);

      // STEP 2: Apply physical image files to server
      // check if user attached physical images on fill details screen!
      // Read object arguments transferred from Fill Details screen
      for (int i = 0; i < _senaraiAduan.length; i++) {
        var aduanSemasa = _senaraiAduan[i];

        // apply physical byte data selected via FilePicker
        if (aduanSemasa['attachment_file_bytes'] != null) {
          // running in Google Chrome Web browser
          requestMultipart.files.add(http.MultipartFile.fromBytes(
            'attachment_files[]', // $_FILES parameter array name captured in PHP
            aduanSemasa['attachment_file_bytes'],
            filename: aduanSemasa['attachment_path'],
          ));
        } else if (aduanSemasa['attachment_file_path'] != null &&
            aduanSemasa['attachment_file_path'].toString().isNotEmpty) {
          // running on Android Emulator phone
          requestMultipart.files.add(await http.MultipartFile.fromPath(
            'attachment_files[]',
            aduanSemasa['attachment_file_path'],
            filename: aduanSemasa['attachment_path'],
          ));
        }
      }

      debugPrint(
          "📤 MULTIPART STEAM LAUNCHED: Sending ${_senaraiAduan.length} complaints along with physical images tracks...");

      // send stream data to PHP server
      var responStream = await requestMultipart.send();
      var responHasil = await http.Response.fromStream(responStream);

      if (responHasil.statusCode == 200) {
        final Map<String, dynamic> hasil = json.decode(responHasil.body);

        if (hasil['status'] == 'berjaya') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(hasil['mesej'] ??
                      'Complaint successfully submitted along with image evidence!')),
            );

            List<String> ticketIds =
                List<String>.from(hasil['ticket_ids'] ?? []);

            setState(() {
              _senaraiAduan.clear();
            });

            context.push('/complaint/submitted',
              extra: {'ticket_ids': ticketIds},
            );
          }
        } else {
          _tampilMesej(hasil['mesej'] ?? "Failed to save data.");
        }
      } else {
        _tampilMesej("Stream Server Error: Status ${responHasil.statusCode}");
      }
    } catch (e) {
      _tampilMesej("Multipart Connection Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _tampilMesej(String mesej) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesej)),
    );
  }

  Widget buildSubmissionItemCard({
    required String fullName,
    required String email,
    required String category,
    required String department,
    required String description,
    required String phoneNumber,
    required String attachmentName,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusTag(label: 'Complaint'),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Edit',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy)),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Cancel',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ReviewField(label: 'Full Name', value: fullName)),
              const SizedBox(width: 16),
              Expanded(child: ReviewField(label: 'Email', value: email)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child:
                      ReviewField(label: 'Phone Number', value: phoneNumber)),
              const SizedBox(width: 16),
              Expanded(
                  child: ReviewField(label: 'Department', value: department)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: ReviewField(
                      label: 'Complaint Category', value: category)),
              const SizedBox(width: 16),
              Expanded(
                  child: ReviewField(
                      label: 'Assigned To', value: '$category Team')),
            ],
          ),
          const SizedBox(height: 14),
          ReviewField(label: 'Description', value: description),
          const SizedBox(height: 14),
          ReviewField(label: 'Attachment', value: attachmentName),
        ],
      ),
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
                const Text('Confirm All Submissions',
                    style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                const Text(
                  "Review everything before sending — once submitted, these cannot be edited.",
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                const StepTracker(currentStep: 3),
                const SizedBox(height: 22),
                Text(
                  'ALL ITEMS IN THIS SUBMISSION (${_senaraiAduan.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (_senaraiAduan.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text(
                            'No complaints to submit. Please add another item.')),
                  ),
                ..._senaraiAduan.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> aduan = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: buildSubmissionItemCard(
                      fullName:
                          _safeLiveName, //  Mengikut emel login semasa!
                      email:
                          _safeLiveEmail, //  Mengikut emel login semasa!
                      category: aduan['category'] ?? 'No Category',
                      department: aduan['department'] ?? 'No Department',
                      description: aduan['description'] ?? 'No Description',
                      phoneNumber: aduan['phone_number'] ?? 'No Phone Number',
                      attachmentName: aduan['attachment_path'] ??
                          aduan['attachment_name'] ??
                          'No attachment',
                      onEdit: () {
                        context.push('/complaint/fill',
                            extra: aduan);
                      },
                      onCancel: () => _tampilDialogPadam(index),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                const InfoBanner(
                  tone: BannerTone.warning,
                  title:
                      'Once you click Submit All, all items above will be submitted and cannot be changed.',
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SecondaryButton(
                      label: 'Add Another',
                      icon: Icons.add,
                      onPressed: _bukaDialogAddAnother,
                    ),
                    _isSending
                        ? const CircularProgressIndicator()
                        : SuccessButton(
                            label: 'Submit All',
                            icon: Icons.send_outlined,
                            onPressed: () {
                              _simpanSemuaAduanKeDatabase();
                            },
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
}
