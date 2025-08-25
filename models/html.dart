class HtmlUtils {
  /// Strips HTML tags from a string and returns clean text
  static String stripHtmlTags(String htmlString) {
    if (htmlString.isEmpty) return htmlString;

    // Remove HTML tags using RegExp
    final RegExp htmlTagRegExp = RegExp(r'<[^>]*>');
    String cleanText = htmlString.replaceAll(htmlTagRegExp, '');

    cleanText = cleanText
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");

    // Clean up extra whitespace
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleanText;
  }
}
