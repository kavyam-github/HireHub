/// Helper utility to clean up HTML descriptions into beautiful, readable plain text.
///
/// Because the API returns raw HTML code for the description field,
/// this helper cleans the text, formats bullet points, and structures line breaks.
class HtmlHelper {
  static String cleanHtml(String htmlString) {
    if (htmlString.isEmpty) return 'No description available.';

    String text = htmlString;

    // 1. Format common HTML lists and structure tags into readable markers
    text = text.replaceAll(RegExp(r'<li>'), '\n• ');
    text = text.replaceAll(RegExp(r'</li>'), '');
    text = text.replaceAll(RegExp(r'</p>'), '\n\n');
    text = text.replaceAll(RegExp(r'<h2>|<h3>|<h4>'), '\n\n');
    text = text.replaceAll(RegExp(r'</h2>|</h3>|</h4>'), '\n');
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');

    // 2. Strip out all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // 3. Unescape common HTML character entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&#x26;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&auml;', 'ä')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&Uuml;', 'Ü')
        .replaceAll('&Auml;', 'Ä')
        .replaceAll('&Ouml;', 'Ö')
        .replaceAll('&szlig;', 'ß');

    // 4. Standardize and cleanup extra spaces and newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }
}
