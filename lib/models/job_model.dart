/// A data model representing a Job posting.
///
/// This class handles JSON parsing from the API and holds the fields:
/// - title
/// - companyName (from company_name)
/// - location
/// - description
/// - url
/// - isBookmarked (a helper field to track if this job is locally bookmarked)
class JobModel {
  final String title;
  final String companyName;
  final String location;
  final String description;
  final String url;
  bool isBookmarked;
  String? translatedDescription;

  JobModel({
    required this.title,
    required this.companyName,
    required this.location,
    required this.description,
    required this.url,
    this.isBookmarked = false,
    this.translatedDescription,
  });

  /// Factory constructor to parse JSON data from the API response
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      title: json['title'] ?? 'No Title',
      companyName: json['company_name'] ?? 'Unknown Company',
      location: json['location'] ?? 'Remote / Not Specified',
      description: json['description'] ?? 'No description provided.',
      url: json['url'] ?? '',
      isBookmarked: false, // Default is false, will be set by Controller if saved
    );
  }

  /// Converts the JobModel back to a JSON-compatible Map (useful for persistence)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company_name': companyName,
      'location': location,
      'description': description,
      'url': url,
    };
  }
}
