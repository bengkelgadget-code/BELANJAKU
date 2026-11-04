import 'package:flutter_test/flutter_test.dart';
import 'package:belanjaku/core/services/update_service.dart';

void main() {
  group('UpdateService.extractBuildNumber', () {
    test('extracts build number from standard semver with build.N format', () {
      expect(UpdateService.extractBuildNumber('v1.0.0-build.10'), 10);
      expect(UpdateService.extractBuildNumber('v1.0.0-build.9'), 9);
      expect(UpdateService.extractBuildNumber('v2.1.3-build.105'), 105);
    });

    test('extracts build number from flutter plus format', () {
      expect(UpdateService.extractBuildNumber('v1.0.0+10'), 10);
      expect(UpdateService.extractBuildNumber('1.0.0+12'), 12);
    });

    test('extracts build number from trailing digits', () {
      expect(UpdateService.extractBuildNumber('release-15'), 15);
      expect(UpdateService.extractBuildNumber('build18'), 18);
    });

    test('returns 0 for non-matching tags', () {
      expect(UpdateService.extractBuildNumber('invalid-tag'), 0);
      expect(UpdateService.extractBuildNumber(''), 0);
    });
  });

  group('UpdateInfo model', () {
    test('constructs correctly', () {
      final info = UpdateInfo(
        tagName: 'v1.0.0-build.11',
        releaseName: 'BELANJAKU v1.0.0 (Build 11)',
        body: 'Perbaikan bug dan penambahan fitur OTA',
        apkDownloadUrl: 'https://github.com/bengkelgadget-code/BELANJAKU/releases/download/v1.0.0-build.11/app-release.apk',
        remoteBuildNumber: 11,
        hasUpdate: true,
        publishedAt: '2026-11-04T12:00:00Z',
      );

      expect(info.tagName, 'v1.0.0-build.11');
      expect(info.remoteBuildNumber, 11);
      expect(info.hasUpdate, true);
      expect(info.apkDownloadUrl, contains('.apk'));
    });
  });
}
