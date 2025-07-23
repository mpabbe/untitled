import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class UpdateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Dio _dio = Dio();
  
  static ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  static ValueNotifier<String> downloadStatus = ValueNotifier('');
  static ValueNotifier<bool> isDownloading = ValueNotifier(false);

  static Future<void> checkAndShowUpdate(BuildContext context) async {
    try {
      final updateAvailable = await isUpdateAvailable();
      if (updateAvailable && context.mounted) {
        final latestVersion = await getLatestVersion();
        _showUpdateDialog(context, latestVersion);
      }
    } catch (e) {
      print('Update check error: $e');
    }
  }

  static Future<bool> isUpdateAvailable() async {
    try {
      final current = await getCurrentVersion();
      final latest = await getLatestVersion();

      if (current == null || latest == null) return false;

      return _compareVersions(current['version'], latest['version']) < 0;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getLatestVersion() async {
    try {
      String platform = Platform.isWindows ? 'windows' : 'android';
      
      final doc = await _firestore
          .collection('app_versions')
          .doc(platform)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  static int _compareVersions(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      int latestPart = i < latestParts.length ? latestParts[i] : 0;

      if (currentPart < latestPart) return -1;
      if (currentPart > latestPart) return 1;
    }
    return 0;
  }

  static void _showUpdateDialog(BuildContext context, Map<String, dynamic>? versionInfo) {
    if (versionInfo == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => UpdateDialog(versionInfo: versionInfo),
    );
  }

  static Future<void> downloadAndInstall(String downloadUrl, String fileName) async {
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      downloadStatus.value = 'Yuklanmoqda...';

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
            downloadStatus.value = 'Yuklanmoqda... ${(received / total * 100).toStringAsFixed(0)}%';
          }
        },
      );

      downloadStatus.value = 'O\'rnatilmoqda...';
      await _installUpdate(filePath);

    } catch (e) {
      downloadStatus.value = 'Xatolik: $e';
      print('Download error: $e');
    } finally {
      isDownloading.value = false;
    }
  }

  static Future<void> _installUpdate(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.start(filePath, [], mode: ProcessStartMode.detached);
        exit(0);
      } else if (Platform.isAndroid) {
        // Android uchun package installer
        await Process.run('am', [
          'start',
          '-t', 'application/vnd.android.package-archive',
          '-d', 'file://$filePath'
        ]);
      }
    } catch (e) {
      print('Install error: $e');
    }
  }
}

class UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> versionInfo;

  const UpdateDialog({Key? key, required this.versionInfo}) : super(key: key);

  @override
  _UpdateDialogState createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: Colors.blue),
          SizedBox(width: 8),
          Text('Yangi versiya'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Versiya: ${widget.versionInfo['version']}'),
          SizedBox(height: 8),
          if (widget.versionInfo['description'] != null)
            Text(widget.versionInfo['description']),
          SizedBox(height: 16),
          
          ValueListenableBuilder<bool>(
            valueListenable: UpdateService.isDownloading,
            builder: (context, isDownloading, child) {
              if (!isDownloading) {
                return SizedBox.shrink();
              }
              
              return Column(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: UpdateService.downloadProgress,
                    builder: (context, progress, child) {
                      return LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  ValueListenableBuilder<String>(
                    valueListenable: UpdateService.downloadStatus,
                    builder: (context, status, child) {
                      return Text(
                        status,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: UpdateService.isDownloading,
          builder: (context, isDownloading, child) {
            return Row(
              children: [
                TextButton(
                  onPressed: isDownloading ? null : () => Navigator.pop(context),
                  child: Text('Keyinroq'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isDownloading ? null : () {
                    Navigator.pop(context);
                    _startDownload();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text(
                    isDownloading ? 'Yuklanmoqda...' : 'Yangilash',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _startDownload() {
    final downloadUrl = widget.versionInfo['downloadUrl'];
    final fileName = Platform.isWindows ? 'update.exe' : 'update.apk';
    
    if (downloadUrl != null) {
      UpdateService.downloadAndInstall(downloadUrl, fileName);
    }
  }
}