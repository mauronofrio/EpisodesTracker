import 'package:episodes_tracker/updates/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('UpdateChecker.fetchLatestRelease', () {
    test('parses tag name and apk asset URL', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.github.com/repos/mauronofrio/episodes-tracker/releases/latest',
        );
        return http.Response('''
{
  "tag_name": "v1.2.0",
  "assets": [
    {"name": "app-release.apk", "browser_download_url": "https://github.com/mauronofrio/episodes-tracker/releases/download/v1.2.0/app-release.apk"},
    {"name": "source.zip", "browser_download_url": "https://example.com/source.zip"}
  ]
}
''', 200);
      });

      final checker = UpdateChecker(
        httpClient: mockClient,
        owner: 'mauronofrio',
        repo: 'episodes-tracker',
      );
      final release = await checker.fetchLatestRelease();

      expect(release!.tagName, 'v1.2.0');
      expect(
        release.apkDownloadUrl,
        'https://github.com/mauronofrio/episodes-tracker/releases/download/v1.2.0/app-release.apk',
      );
    });

    test('returns null when the repo has no releases (404)', () async {
      final mockClient = MockClient(
        (request) async => http.Response('Not Found', 404),
      );
      final checker = UpdateChecker(
        httpClient: mockClient,
        owner: 'mauronofrio',
        repo: 'episodes-tracker',
      );

      expect(await checker.fetchLatestRelease(), isNull);
    });

    test('returns null apkDownloadUrl when no .apk asset is attached', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          '{"tag_name": "v1.0.0", "assets": []}',
          200,
        ),
      );
      final checker = UpdateChecker(
        httpClient: mockClient,
        owner: 'mauronofrio',
        repo: 'episodes-tracker',
      );

      final release = await checker.fetchLatestRelease();
      expect(release!.apkDownloadUrl, isNull);
    });

    test('throws on unexpected non-200/404 status', () async {
      final mockClient = MockClient(
        (request) async => http.Response('error', 500),
      );
      final checker = UpdateChecker(
        httpClient: mockClient,
        owner: 'mauronofrio',
        repo: 'episodes-tracker',
      );

      expect(() => checker.fetchLatestRelease(), throwsException);
    });
  });

  group('UpdateChecker.isNewer', () {
    test('detects a newer patch version', () {
      expect(
        UpdateChecker.isNewer(currentVersion: '1.0.0', latestTag: 'v1.0.1'),
        isTrue,
      );
    });

    test('detects equal versions as not newer', () {
      expect(
        UpdateChecker.isNewer(currentVersion: '1.2.0', latestTag: 'v1.2.0'),
        isFalse,
      );
    });

    test('detects an older version as not newer', () {
      expect(
        UpdateChecker.isNewer(currentVersion: '2.0.0', latestTag: 'v1.9.9'),
        isFalse,
      );
    });

    test('compares numerically, not lexicographically (1.10.0 > 1.9.0)', () {
      expect(
        UpdateChecker.isNewer(currentVersion: '1.9.0', latestTag: 'v1.10.0'),
        isTrue,
      );
    });

    test('strips the pubspec build-number suffix from currentVersion', () {
      expect(
        UpdateChecker.isNewer(
          currentVersion: '1.0.0+5',
          latestTag: 'v1.0.1',
        ),
        isTrue,
      );
    });

    test('strips an uppercase "V" tag prefix (GitHub tags aren\'t forced '
        'to lowercase)', () {
      expect(
        UpdateChecker.isNewer(currentVersion: '0.9.0', latestTag: 'V1.0.0'),
        isTrue,
      );
    });
  });
}
