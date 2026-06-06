import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/job_controller.dart';
import '../models/job_model.dart';
import 'job_detail_inspector.dart';

/// Screen 1: The Job Dashboard.
/// Displays a search bar, filtering tabs (All vs Bookmarked),
/// and a responsive feed of live job openings from the API.
class JobDashboard extends StatelessWidget {
  JobDashboard({super.key});

  // Locate our GetX controller
  final JobController controller = Get.put(JobController());

  // A local reactive state to toggle between "All Jobs" and "Bookmarks"
  final RxBool showOnlyBookmarks = false.obs;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrButtonPressedTooLongAgo =
            controller.lastPressedTime == null ||
                now.difference(controller.lastPressedTime!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrButtonPressedTooLongAgo) {
          controller.lastPressedTime = now;
          Get.snackbar(
            'Exit App',
            'Press back again to exit',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF1E293B),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App logo icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'HireHub',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFE2E8F0)),
          ),
          actions: [
            // Quick refresh button in AppBar
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
              tooltip: 'Refresh Jobs',
              onPressed: () => controller.fetchJobs(),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search Bar & Filter Section
              _buildSearchAndFilters(),

              // Main Job List Feed (reactive state wrapper)
              Expanded(
                child: Obx(() {
                  // 1. Data Loading State
                  if (controller.isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                              strokeWidth: 3.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Fetching live job openings...',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }

                  // 2. Network Pipeline Resilience / Error Handling State
                  if (controller.hasError.value) {
                    return _buildErrorWidget();
                  }

                  // Apply search filter and bookmark toggle filter
                  final List<JobModel> jobsToShow = showOnlyBookmarks.value
                      ? controller.filteredJobs.where((j) => controller.bookmarkedUrls.contains(j.url)).toList()
                      : controller.filteredJobs;

                  // 3. Empty State (No results match search query or empty bookmarks)
                  if (jobsToShow.isEmpty) {
                    return _buildEmptyWidget();
                  }

                  // 4. Content State (Beautiful List Card Feed)
                  return RefreshIndicator(
                    color: const Color(0xFF2563EB),
                    backgroundColor: Colors.white,
                    onRefresh: () => controller.fetchJobs(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: jobsToShow.length,
                      itemBuilder: (context, index) {
                        final job = jobsToShow[index];
                        return _buildJobCard(context, job);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the search input field and filtering chips
  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Search Bar Text Field
          TextField(
            onChanged: (value) => controller.filterJobs(value),
            style: const TextStyle(color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Search by title or company...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 14),

          // Custom Filter Toggle Tabs
          Obx(() {
            return Row(
              children: [
                _buildFilterTab(
                  label: 'All Jobs',
                  isSelected: !showOnlyBookmarks.value,
                  icon: Icons.work_outline_rounded,
                  onTap: () => showOnlyBookmarks.value = false,
                ),
                const SizedBox(width: 12),
                _buildFilterTab(
                  label: 'Saved (${controller.bookmarkedUrls.length})',
                  isSelected: showOnlyBookmarks.value,
                  icon: Icons.bookmark_border_rounded,
                  onTap: () => showOnlyBookmarks.value = true,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Helper widget to build a filter selection button
  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget that displays when an API network error occurs
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oops! Connection issue',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            // Custom Reload Action Button
            ElevatedButton.icon(
              onPressed: () => controller.fetchJobs(),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget that displays when no jobs are found (empty state)
  Widget _buildEmptyWidget() {
    final isSearching = controller.searchQuery.value.isNotEmpty;
    final isBookmarkMode = showOnlyBookmarks.value;

    String titleText = 'No jobs found';
    String subText = 'Please try searching for something else.';
    IconData icon = Icons.search_off_rounded;

    if (isBookmarkMode && !isSearching) {
      titleText = 'No saved jobs yet';
      subText = 'Tap the bookmark icon on job cards to save them for later.';
      icon = Icons.bookmark_border_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 56, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              titleText,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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

  /// Builds an individual job card list item
  Widget _buildJobCard(BuildContext context, JobModel job) {
    // Unique hero tags to ensure clean animation matching between screens
    final String heroTag = 'card_${job.url}';
    final avatarColor = _getAvatarColor(job.companyName);
    final initials = job.companyName.isNotEmpty
        ? job.companyName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Hero(
      tag: heroTag,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        // Keeps cards looking nice during transition instead of stretching
        return Material(
          color: Colors.transparent,
          child: toHeroContext.widget,
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Screen 2 Trigger Hook - navigates to details page
            Get.to(() => JobDetailInspector(job: job, heroTag: heroTag));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Avatar with initials
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: avatarColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Job info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with bookmark toggle
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Bookmark button (reactive toggle)
                          Obx(() {
                            final isBookmarked = controller.bookmarkedUrls.contains(job.url);
                            return GestureDetector(
                              onTap: () => controller.toggleBookmark(job),
                              child: Icon(
                                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: isBookmarked ? const Color(0xFFF97316) : const Color(0xFFCBD5E1),
                                size: 22,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Company Name badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: avatarColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          job.companyName,
                          style: TextStyle(
                            color: avatarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Location tag
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.location,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
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
          ),
        ),
      ),
    );
  }
}
