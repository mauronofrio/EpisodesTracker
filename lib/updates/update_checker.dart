import 'dart:convert';

import 'package:http/http.dart' as http;

class ReleaseInfo {
  final String tagName;
  final String? apkDownloadUrl;

  const ReleaseInfo({required this.tagName, required this.apkDownloadUrl});
}

/// Checks the app's GitHub Releases feed for a newer version than the one
/// currently installed. The repository must be public (the app has no
/// GitHub credentials embedded), matching the same pattern used in
/// mauronofrio/cinema-disponibilita-posti.
class UpdateChecker {
  final http.Client _httpClient;
  final String owner;
  final String repo;

  UpdateChecker({
    required http.Client httpClient,
    required this.owner,
    required this.repo,
  }) : _httpClient = httpClient;

  /// Returns null if the repository has no releases yet (404).
  Future<ReleaseInfo?> fetchLatestRelease() async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/releases/latest',
    );
    final response = await _httpClient.get(
      uri,
      headers: {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('GitHub releases API error ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final assets = (json['assets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final apkAsset = assets.where(
      (a) => (a['name'] as String? ?? '').endsWith('.apk'),
    );

    return ReleaseInfo(
      tagName: json['tag_name'] as String,
      apkDownloadUrl: apkAsset.isEmpty
          ? null
          : apkAsset.first['browser_download_url'] as String?,
    );
  }

  /// Compares two dotted version strings numerically (so "1.10.0" is newer
  /// than "1.9.0", unlike a plain string comparison). An optional leading
  /// "v" is stripped from both. Non-numeric/malformed segments are treated
  /// as 0.
  static bool isNewer({
    required String currentVersion,
    required String latestTag,
  }) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(latestTag);
    for (var i = 0; i < 3; i++) {
      if (latest[i] != current[i]) return latest[i] > current[i];
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    // Case-insensitive: GitHub tags aren't guaranteed to use a lowercase
    // "v" prefix (e.g. a release tagged "V1.0.0"), and a missed strip here
    // silently breaks every segment's int.tryParse, parsing the whole
    // version as 0.0.0 - never detected as newer than anything.
    final stripped = version.toLowerCase().startsWith('v')
        ? version.substring(1)
        : version;
    // Drop any build-number suffix (e.g. "1.0.0+3" from pubspec's version).
    final core = stripped.split('+').first;
    final parts = core.split('.');
    return List.generate(3, (i) {
      if (i >= parts.length) return 0;
      return int.tryParse(parts[i]) ?? 0;
    });
  }
}
