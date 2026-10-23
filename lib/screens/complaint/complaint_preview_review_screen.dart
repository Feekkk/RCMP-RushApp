import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// Interface 6: "Submit a Complaint" — Step 2: Preview & Review.
class ComplaintPreviewReviewScreen extends StatelessWidget {
  const ComplaintPreviewReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. SAFELY CAPTURE ALL DATA FROM PREVIOUS SCREEN
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic> dataAduan =
        (args != null) ? args as Map<String, dynamic> : {};

    // Retrieve complaint data filled by user
    String category = dataAduan['category'] ?? 'No Category';
    String description = dataAduan['description'] ?? 'No Description';
    String phoneNumber = dataAduan['phone_number'] ?? 'No Phone Number';
    String department = dataAduan['department'] ?? 'No Department';
    String attachmentName = dataAduan['attachment_path'] ?? 'No attachment';

    // 2. RETRIEVE DYNAMIC USER PROFILE DATA FROM DATABASE (LOGIN RESULT)
    // If data is missing, use default values
    String full_name = dataAduan['full_name'] ?? 'NUR SYAFIQAH SYAZA';
    String email = dataAduan['email'] ?? 'syafiqahsyaza@gmail.com';

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
                const SizedBox(height: 18),
                const Text('Submit a Complaint',
                    style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                const Text(
                  'Fill the details and your assigned department will attend to your request.',
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                const StepTracker(currentStep: 2),
                const SizedBox(height: 22),
                const Text('Review Your Complaint',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text(
                  'Please check everything carefully before submitting.',
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                const SectionHeading(title: 'Your Information'),
                const SizedBox(height: 14),

                // === DYNAMIC STAFF INFORMATION DISPLAY (FROM DATABASE) ===
                Row(
                  children: [
                    Expanded(
                        child:
                            ReviewField(label: 'Full Name', value: full_name)),
                    const SizedBox(width: 16),
                    Expanded(
                        child:
                            ReviewField(label: 'Email Address', value: email)),
                  ],
                ),
                const SizedBox(height: 16),

                // === DYNAMIC PHONE NUMBER & DEPARTMENT DISPLAY (USER INPUT) ===
                Row(
                  children: [
                    Expanded(
                        child: ReviewField(
                            label: 'Phone Number', value: phoneNumber)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: ReviewField(
                            label: 'My Department / Faculty',
                            value: department)),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 20),
                const SectionHeading(title: 'Complaint Details'),
                const SizedBox(height: 14),

                // === DYNAMIC CATEGORY DISPLAY ===
                Row(
                  children: [
                    Expanded(
                        child: ReviewField(label: 'Category', value: category)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: ReviewField(
                            label: 'Assigned To', value: '$category Team')),
                  ],
                ),
                const SizedBox(height: 16),

                // === show desc ===
                ReviewField(
                  label: 'Description',
                  value: description,
                ),
                const SizedBox(height: 16),
                ReviewField(label: 'Attachment', value: attachmentName),
                const SizedBox(height: 22),
                const InfoBanner(
                  tone: BannerTone.warning,
                  title: "Once submitted, this complaint can't be edited",
                ),
                const SizedBox(height: 12),
                const InfoBanner(
                  tone: BannerTone.success,
                  title:
                      'Working hours active — complaint will be attended to today.',
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      label: 'Back to Edit',
                      icon: Icons.arrow_back,
                      onPressed: () {
                        // Hanya kembali ke skrin Edit tanpa menyimpan apa-apa data
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    SuccessButton(
                      label: 'Next: Review All',
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        List<dynamic> existingList =
                            dataAduan['existing_list'] ?? [];

                        Map<String, dynamic> newComplaint = {
                          'category': category,
                          'description': description,
                          'phone_number': phoneNumber,
                          'department': department,
                          'full_name': full_name,
                          'email': email,
                          'attachment_path': attachmentName,
                          'attachment_file_bytes':
                              dataAduan['attachment_file_bytes'],
                          'attachment_file_path':
                              dataAduan['attachment_file_path'],
                        };

                        List<Map<String, dynamic>> allComplaints = [
                          ...existingList
                              .map((e) => Map<String, dynamic>.from(e)),
                          newComplaint,
                        ];

                        context.push('/complaint/confirm',
                          extra: allComplaints,
                        );
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
