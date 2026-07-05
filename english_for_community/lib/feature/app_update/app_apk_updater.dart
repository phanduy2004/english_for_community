import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum ApkUpdateStage { idle, checkingPermission, downloading, opening, error }

class ApkUpdateProgress {
  final ApkUpdateStage stage;
  final double progress;
  final String? error;

  const ApkUpdateProgress(
    this.stage, {
    this.progress = 0,
    this.error,
  });
}

class AppApkUpdater {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  Future<bool> downloadAndInstall({
    required String url,
    required int versionCode,
    required void Function(ApkUpdateProgress progress) onProgress,
  }) async {
    CancelToken? requestCancelToken;
    try {
      onProgress(const ApkUpdateProgress(ApkUpdateStage.checkingPermission));
      final status = await Permission.requestInstallPackages.status;
      final granted = status.isGranted
          ? true
          : (await Permission.requestInstallPackages.request()).isGranted;
      if (!granted) {
        return false;
      }

      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        onProgress(const ApkUpdateProgress(
          ApkUpdateStage.error,
          error: 'Unable to access app storage.',
        ));
        return false;
      }

      await _deleteOldApks(dir);
      final path = '${dir.path}/e4c-update-$versionCode.apk';

      requestCancelToken = CancelToken();
      _cancelToken = requestCancelToken;
      onProgress(const ApkUpdateProgress(ApkUpdateStage.downloading));
      await _dio.download(
        url,
        path,
        cancelToken: requestCancelToken,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          onProgress(ApkUpdateProgress(
            ApkUpdateStage.downloading,
            progress: received / total,
          ));
        },
      );

      onProgress(const ApkUpdateProgress(ApkUpdateStage.opening));
      final result = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return true;
      }
      onProgress(ApkUpdateProgress(
        ApkUpdateStage.error,
        error: error.message,
      ));
      return false;
    } catch (error) {
      onProgress(ApkUpdateProgress(
        ApkUpdateStage.error,
        error: error.toString(),
      ));
      return false;
    } finally {
      if (identical(_cancelToken, requestCancelToken)) {
        _cancelToken = null;
      }
    }
  }

  Future<void> _deleteOldApks(Directory dir) async {
    await for (final entry in dir.list(followLinks: false)) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.isEmpty
          ? entry.path
          : entry.uri.pathSegments.last;
      if (!name.startsWith('e4c-update-') || !name.endsWith('.apk')) {
        continue;
      }
      try {
        await entry.delete();
      } catch (_) {
        // Best-effort cleanup should not block the update flow.
      }
    }
  }

  void cancel() {
    _cancelToken?.cancel();
  }

  void dispose() {
    cancel();
    _dio.close(force: true);
  }
}
