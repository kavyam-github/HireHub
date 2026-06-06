import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/job_controller.dart';
import '../models/job_model.dart';
import '../utils/html_helper.dart';

/// Screen 2: Job Detail Inspector.
/// Exposes detailed job specifications, descriptions, and
/// contains an action layer to launch external job applications.
class JobDetailInspector extends StatelessWidget {
  final JobModel job;
  final String heroTag;

  JobDetailInspector({
    super.key,
    required this.job,
    required this.heroTag,
  });

  // Locate the controller to easily update bookmark flags reactively
  final JobController controller = Get.find<JobController>();

  /// Helper to safely launch the job board source web page
  Future<void> _launchApplyUrl(BuildContext context, String urlString) async {
    if (urlString.isEmpty) {
      Get.snackbar(
        'Unable to Open',
        'No valid application URL was provided for this job.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEF3C7),
        colorText: const Color(0xFF92400E),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final Uri url = Uri.parse(urlString);
    try {
      // Launch using external application to ensure compatibility
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw 'Launch returned false';
      }
    } catch (e) {
      Get.snackbar(
        'Link Failed',
        'Could not open application link in your browser.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFF991B1B),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  /// Generates a color for the company avatar based on company name
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFFEC4899),
      const Color(0xFFF97316),
      const Color(0xFF14B8A6),
      const Color(0xFF059669),
      const Color(0xFFEAB308),
      const Color(0xFF6366F1),
    ];
    final index = name.codeUnits.fold(0, (sum, c) => sum + c) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    // Clean up html tags inside description using our HtmlHelper utility
    final String cleanDescriptionText = HtmlHelper.cleanHtml(job.description);
    final avatarColor = _getAvatarColor(job.companyName);
    final initials = job.companyName.isNotEmpty
        ? job.companyName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
        actions: [
          // Enable users to toggle bookmarks directly from details view
          Obx(() {
            final isBookmarked = controller.bookmarkedUrls.contains(job.url);
            return IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isBookmarked ? const Color(0xFFF97316) : const Color(0xFF64748B),
              ),
              onPressed: () => controller.toggleBookmark(job),
            );
          }),
        ],
      ),
      body: Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              // Comprehensive scroll view containing the job metadata header and clean description
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card Info
                      _buildHeaderCard(avatarColor, initials),
                      const SizedBox(height: 20),

                      // Translation toggle + Section Title row
                      _buildDescriptionHeader(),
                      const SizedBox(height: 14),

                      // Flowing text container for the clean description body
                      Obx(() {
                        final translatedText = controller.translatedDescriptions[job.url];
                        final isTranslated = translatedText != null;
                        final displayText = isTranslated ? translatedText : cleanDescriptionText;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show translation badge if translated
                            if (isTranslated)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF6EE7B7)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Translated to English',
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 14,
                                  height: 1.7,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action Layer: Bottom Application Button Box
              _buildActionLayer(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the description section header with translate button
  Widget _buildDescriptionHeader() {
    return Row(
      children: [
        // Section Title: "Job Description"
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Job Description',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
            ],
          ),
        ),

        // Translate Button
        Obx(() {
          final isTranslating = controller.translatingJobs.contains(job.url);
          final isTranslated = controller.translatedDescriptions.containsKey(job.url);

          return GestureDetector(
            onTap: isTranslating ? null : () => controller.translateDescription(job),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isTranslated
                    ? const Color(0xFFECFDF5)
                    : isTranslating
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isTranslated
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isTranslating)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  else
                    Icon(
                      Icons.translate_rounded,
                      size: 15,
                      color: isTranslated ? const Color(0xFF059669) : const Color(0xFF2563EB),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    isTranslating
                        ? 'Translating...'
                        : isTranslated
                            ? 'Show Original'
                            : 'Translate',
                    style: TextStyle(
                      color: isTranslated ? const Color(0xFF059669) : const Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Builds the summary header block showing Title, Company Name, and Location
  Widget _buildHeaderCard(Color avatarColor, String initials) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company avatar + name row
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: avatarColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Name
                    Text(
                      job.companyName,
                      style: TextStyle(
                        color: avatarColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.location,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Job Title
          Text(
            job.title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the bottom 'Apply Now' action button drawer
  Widget _buildActionLayer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2563EB), // Blue
                Color(0xFF7C3AED), // Purple
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _launchApplyUrl(context, job.url),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Apply Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
