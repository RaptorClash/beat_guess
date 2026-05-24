import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../utils/NotificationHelper.dart';
import '../services/language_service.dart';

class UpdateService {
  final String githubApiUrl =
      'https://api.github.com/repos/RaptorClash/beat_guess/releases/latest';

  Future<void> checkForUpdate(BuildContext context) async {
    if (kIsWeb) {
      return;
    }
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final response = await Dio().get(
        githubApiUrl,
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String latestVersion = data['tag_name'];
        String releaseUrl = data['html_url'];
        List assets = data['assets'] ?? [];

        // 3. Versionen vergleichen
        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          _handleUpdateFlow(context, latestVersion, releaseUrl, assets);
        }
      }
    } catch (e) {
      NotificationHelper.showError(t('error_github_update_check'));
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    final cleanCurrent = current.replaceAll('v', '').split('.');
    final cleanLatest = latest.replaceAll('v', '').split('.');

    for (int i = 0; i < 3; i++) {
      int cNum = i < cleanCurrent.length
          ? int.tryParse(cleanCurrent[i]) ?? 0
          : 0;
      int lNum = i < cleanLatest.length ? int.tryParse(cleanLatest[i]) ?? 0 : 0;

      if (lNum > cNum) return true;
      if (lNum < cNum) return false;
    }
    return false;
  }

  void _handleUpdateFlow(
    BuildContext context,
    String latestVersion,
    String releaseUrl,
    List assets,
  ) {
    String? downloadUrl;
    String platformInstructions = "";

    if (Platform.isAndroid) {
      final apkAsset = assets.firstWhere(
        (asset) => asset['name'].toString().endsWith('.apk'),
        orElse: () => null,
      );
      if (apkAsset != null) downloadUrl = apkAsset['browser_download_url'];
    } else if (Platform.isWindows) {
      final windowsAsset = assets.firstWhere(
        (asset) =>
            asset['name'].toString().contains('windows') ||
            asset['name'].toString().endsWith('.exe'),
        orElse: () => null,
      );
      if (windowsAsset != null)
        downloadUrl = windowsAsset['browser_download_url'];
      platformInstructions = t('download_update');
    } else if (Platform.isMacOS) {
      final macAsset = assets.firstWhere(
        (asset) =>
            asset['name'].toString().contains('macos') ||
            asset['name'].toString().endsWith('.dmg'),
        orElse: () => null,
      );
      if (macAsset != null) downloadUrl = macAsset['browser_download_url'];
    } else if (Platform.isLinux) {
      final linuxAsset = assets.firstWhere(
        (asset) =>
            asset['name'].toString().contains('linux') ||
            asset['name'].toString().endsWith('.tar.gz'),
        orElse: () => null,
      );
      if (linuxAsset != null) downloadUrl = linuxAsset['browser_download_url'];
    }

    final finalUrl = downloadUrl ?? releaseUrl;

    _showUpdateDialog(context, latestVersion, finalUrl, platformInstructions);
  }

  void _showUpdateDialog(
    BuildContext context,
    String version,
    String targetUrl,
    String dynamicText,
  ) {
    showDialog(
      context: context,
      barrierDismissible: Platform.isIOS ? true : false,
      builder: (context) => AlertDialog(
        title: Text('Update verfügbar! (v$version)'),
        content: Text(
          Platform.isIOS
              ? t('newVersionAvailable_iOS')
              : t('downloadLatestVersion$dynamicText'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Platform.isIOS ? t('close') : t('later')),
          ),
          if (!Platform.isIOS)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (Platform.isAndroid && targetUrl.endsWith('.apk')) {
                  _downloadAndInstallAndroid(targetUrl);
                } else {
                  _launchBrowser(targetUrl);
                }
              },
              child: Text(t('update')),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstallAndroid(String url) async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      String savePath = "${tempDir.path}/update.apk";

      await Dio().download(url, savePath);
      await OpenFilex.open(savePath);
    } catch (e) {
      NotificationHelper.showError(t('error_android_update', {'error': e.toString()}));
    }
  }

  Future<void> _launchBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      NotificationHelper.showError(t('unable_open_url'));
    }
  }
}
