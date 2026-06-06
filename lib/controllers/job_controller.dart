import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';
import '../utils/html_helper.dart';

/// GetX controller to handle API fetching, search filtering, bookmarks, and translation.
///
/// By using GetX, we isolate the application state from the UI layers.

class JobController extends GetxController {
  // Reactive list variables that hold all jobs and filtered search results
  final allJobs = <JobModel>[].obs;
  final filteredJobs = <JobModel>[].obs;

  // Reactive variables for tracking different loading states and errors
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // Reactive set of bookmarked job URLs to ensure bookmark persistence across sessions
  final bookmarkedUrls = <String>{}.obs;

  // Store the active search query
  final searchQuery = ''.obs;

  // Translation state tracker — maps job URL to loading status
  final translatingJobs = <String>{}.obs;

  // Reactive map holding translated descriptions: {jobUrl: translatedText}
  final translatedDescriptions = <String, String>{}.obs;

  // Track the last back press time for exit verification
  DateTime? lastPressedTime;

  @override
  void onInit() {
    super.onInit();
    // Fetch bookmarks first, then download jobs from API
    initController();
  }

  /// Initial startup routine
  Future<void> initController() async {
    await loadBookmarks();
    await fetchJobs();
  }

  /// Loads locally saved bookmarks from device SharedPreferences
  Future<void> loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedBookmarks = prefs.getStringList('bookmarked_urls');
      if (savedBookmarks != null) {
        bookmarkedUrls.assignAll(savedBookmarks.toSet());
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  /// Saves local bookmarks to device SharedPreferences
  Future<void> saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('bookmarked_urls', bookmarkedUrls.toList());
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  /// Downloads jobs from the Arbeitnow API and updates the state variables.
  /// Handles both formatting errors and connection Drops gracefully.
  Future<void> fetchJobs() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final response = await http.get(Uri.parse('https://www.arbeitnow.com/api/job-board-api'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('data') && responseData['data'] is List) {
          final List<dynamic> jobList = responseData['data'];
          
          final List<JobModel> parsedJobs = jobList.map((jobJson) {
            final job = JobModel.fromJson(jobJson);
            // Restore bookmarked flag if this job was bookmarked previously
            if (bookmarkedUrls.contains(job.url)) {
              job.isBookmarked = true;
            }
            return job;
          }).toList();

          allJobs.assignAll(parsedJobs);
          // Apply search filter in case user was typing while reload happened
          filterJobs(searchQuery.value);
        } else {
          hasError.value = true;
          errorMessage.value = 'API returned data in an invalid format.';
        }
      } else {
        hasError.value = true;
        errorMessage.value = 'Failed to load jobs (Error Code: ${response.statusCode})';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Network timeout or no internet connection. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Filters jobs responsively based on title or company name tags
  void filterJobs(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      filteredJobs.assignAll(allJobs);
    } else {
      final lowercaseQuery = query.toLowerCase();
      filteredJobs.assignAll(
        allJobs.where((job) {
          return job.title.toLowerCase().contains(lowercaseQuery) ||
                 job.companyName.toLowerCase().contains(lowercaseQuery);
        }).toList(),
      );
    }
  }

  /// Toggles a job's bookmark state and updates local storage persistence
  void toggleBookmark(JobModel job) {
    if (bookmarkedUrls.contains(job.url)) {
      bookmarkedUrls.remove(job.url);
      job.isBookmarked = false;
    } else {
      bookmarkedUrls.add(job.url);
      job.isBookmarked = true;
    }
    
    // Save to SharedPreferences
    saveBookmarks();
    
    // Refresh both lists to update the UI heart icons
    allJobs.refresh();
    filteredJobs.refresh();
  }

  /// Splits a long text into chunks of approximately [maxLen] characters,
  /// breaking at the nearest newline or sentence boundary to avoid cutting words.
  List<String> _splitIntoChunks(String text, int maxLen) {
    final List<String> chunks = [];
    String remaining = text;

    while (remaining.isNotEmpty) {
      if (remaining.length <= maxLen) {
        chunks.add(remaining);
        break;
      }

      // Try to find a good break point (newline or period) near the limit
      int breakPoint = remaining.lastIndexOf('\n', maxLen);
      if (breakPoint < maxLen ~/ 2) {
        breakPoint = remaining.lastIndexOf('. ', maxLen);
        if (breakPoint < maxLen ~/ 2) {
          breakPoint = remaining.lastIndexOf(' ', maxLen);
        }
      }
      if (breakPoint <= 0) breakPoint = maxLen;

      chunks.add(remaining.substring(0, breakPoint).trim());
      remaining = remaining.substring(breakPoint).trim();
    }

    return chunks;
  }

  /// Translates a single chunk of text using Google Translate GTX API.
  /// Returns the translated text or the original if translation fails.
  Future<String> _translateChunk(String text) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final apiUrl = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=en&dt=t&q=$encodedText';

      final response = await http.get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        if (decoded.isNotEmpty && decoded[0] is List) {
          final List<dynamic> segments = decoded[0];
          final StringBuffer translated = StringBuffer();
          for (var segment in segments) {
            if (segment is List && segment.isNotEmpty) {
              translated.write(segment[0]);
            }
          }
          final String result = translated.toString();
          if (result.isNotEmpty) {
            return result;
          }
        }
      }
    } catch (e) {
      debugPrint('Error translating chunk: $e');
    }
    return text; // Return original if translation fails for this chunk
  }

  /// Translates a job's FULL description to English using the free Google Translate GTX API.
  /// Cleans HTML first, splits into chunks, translates each chunk, and combines results.
  Future<void> translateDescription(JobModel job) async {
    // If already translated, clear translation (toggle behavior)
    if (translatedDescriptions.containsKey(job.url)) {
      translatedDescriptions.remove(job.url);
      return;
    }

    // Mark this job as currently translating
    translatingJobs.add(job.url);

    try {
      // Step 1: Clean the HTML tags from the description first
      final String cleanText = HtmlHelper.cleanHtml(job.description);
      debugPrint('Clean text length: ${cleanText.length}');

      // Step 2: Split into chunks of ~1000 chars (safe for Google URL length limits)
      final List<String> chunks = _splitIntoChunks(cleanText, 1000);
      debugPrint('Total chunks to translate: ${chunks.length}');

      // Step 3: Translate each chunk sequentially
      final List<String> translatedChunks = [];
      for (int i = 0; i < chunks.length; i++) {
        debugPrint('Translating chunk ${i + 1}/${chunks.length} (${chunks[i].length} chars)');
        final translated = await _translateChunk(chunks[i]);
        translatedChunks.add(translated);

        // Small delay between requests to avoid rate limiting
        if (i < chunks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      // Step 4: Combine all translated chunks
      final fullTranslation = translatedChunks.join('\n\n');

      if (fullTranslation.isNotEmpty && fullTranslation != cleanText) {
        translatedDescriptions[job.url] = fullTranslation;
        debugPrint('Full translation successful!');
      } else {
        Get.snackbar(
          'Translation',
          'The description appears to already be in English.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFEF3C7),
          colorText: const Color(0xFF92400E),
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      Get.snackbar(
        'Translation Failed',
        'Could not connect to translation service. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFF991B1B),
        margin: const EdgeInsets.all(16),
      );
    } finally {
      translatingJobs.remove(job.url);
    }
  }
}
