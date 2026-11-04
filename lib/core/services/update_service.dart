import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class UpdateInfo {
  final String tagName;
  final String releaseName;
  final String body;
  final String? apkDownloadUrl;
  final int remoteBuildNumber;
  final bool hasUpdate;
  final String publishedAt;

  UpdateInfo({
    required this.tagName,
    required this.releaseName,
    required this.body,
    required this.apkDownloadUrl,
    required this.remoteBuildNumber,
    required this.hasUpdate,
    required this.publishedAt,
  });
}

class UpdateService {
  static const MethodChannel _channel = MethodChannel('com.bengkel.belanjaku/ota_update');

  static String get _latestReleaseUrl =>
      'https://api.github.com/repos/${AppConstants.githubOwner}/${AppConstants.githubRepo}/releases/latest';

  /// Check GitHub for newer release
  static Future<UpdateInfo?> checkForUpdate() async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(_latestReleaseUrl));
      request.headers.set('User-Agent', 'BELANJAKU-MobileApp');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      final tagName = data['tag_name'] as String? ?? '';
      final releaseName = data['name'] as String? ?? tagName;
      final body = data['body'] as String? ?? '';
      final publishedAt = data['published_at'] as String? ?? '';

      // Find suitable APK asset (prioritize arm64-v8a for modern phones, fallback to first .apk or html_url)
      String? apkUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        // Priority 1: arm64-v8a for modern Android phones
        for (final item in assets) {
          final asset = item as Map<String, dynamic>;
          final name = asset['name'] as String? ?? '';
          if (name.contains('arm64-v8a') && name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
        // Priority 2: any .apk asset
        if (apkUrl == null) {
          for (final item in assets) {
            final asset = item as Map<String, dynamic>;
            final name = asset['name'] as String? ?? '';
            if (name.endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }
      }

      // If no direct asset found, fallback to release html url
      apkUrl ??= data['html_url'] as String?;

      final remoteBuild = extractBuildNumber(tagName);
      final hasUpdate = remoteBuild > AppConstants.buildNumber;

      return UpdateInfo(
        tagName: tagName,
        releaseName: releaseName,
        body: body,
        apkDownloadUrl: apkUrl,
        remoteBuildNumber: remoteBuild,
        hasUpdate: hasUpdate,
        publishedAt: publishedAt,
      );
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
  }

  /// Extract build number from tag strings like:
  /// "v1.0.0-build.10" -> 10
  /// "v1.0.0+11" -> 11
  /// "12" -> 12
  static int extractBuildNumber(String tag) {
    final match = RegExp(r'(?:build\.|\+)(\d+)').firstMatch(tag);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    final rawNumber = RegExp(r'(\d+)$').firstMatch(tag);
    if (rawNumber != null) {
      return int.tryParse(rawNumber.group(1)!) ?? 0;
    }
    return 0;
  }

  /// Open APK download link in Android browser/package installer
  static Future<bool> openDownloadUrl(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
