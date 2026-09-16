import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/upload_status.dart';
import '../../domain/repository/upload_repository.dart';

// Visible named folder, not appDataFolder — this is a comparison tool, so
// uploaded files need to be eyeballed across approaches.
class GoogleDriveUploadRepositoryImpl implements UploadRepository {
  static const _scopes = <String>[drive.DriveApi.driveFileScope];

  bool _initialized = false;
  GoogleSignInAccount? _account;
  String? _rootFolderId;
  // Keyed by day-folder name (e.g. "29082026") — avoids a Drive list query
  // per chunk upload for folders already resolved/created this app run.
  final Map<String, String> _dayFolderIds = {};

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  Future<GoogleSignInAccount?> _ensureSignedIn() async {
    await _ensureInitialized();
    if (_account != null) return _account;

    try {
      final lightweight = GoogleSignIn.instance.attemptLightweightAuthentication();
      final account =
          lightweight is Future<GoogleSignInAccount?> ? await lightweight : null;
      if (account != null) {
        _account = account;
        return _account;
      }
    } catch (_) {
      // Fall through to explicit sign-in.
    }

    try {
      _account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException {
      _account = null;
    }
    return _account;
  }

  @override
  Future<UploadStatus> uploadArtifacts(List<UploadRequest> requests) async {
    if (requests.isEmpty) {
      return const UploadError('Nothing to upload.');
    }

    final account = await _ensureSignedIn();
    if (account == null) {
      return const UploadNotSignedIn();
    }

    try {
      final authorization =
          await account.authorizationClient.authorizeScopes(_scopes);
      final client = authorization.authClient(scopes: _scopes);
      final driveApi = drive.DriveApi(client);
      final rootFolderId = await _ensureRootFolder(driveApi);

      final links = <String>[];
      for (final request in requests) {
        final dayFolderId = await _ensureDayFolder(
          driveApi,
          rootFolderId,
          request.dayFolderName,
        );
        final artifact = request.artifact;
        final file = File(artifact.path);
        final media = drive.Media(file.openRead(), artifact.sizeBytes);
        final metadata = drive.File()
          ..name = request.remoteFileName
          ..description = request.description
          ..parents = [dayFolderId];
        final created = await driveApi.files.create(
          metadata,
          uploadMedia: media,
          $fields: 'id, webViewLink',
        );
        links.add(
          created.webViewLink ??
              'https://drive.google.com/file/d/${created.id}/view',
        );
      }
      return UploadSuccess(fileLinks: links);
    } on drive.DetailedApiRequestError catch (e) {
      return UploadError(e.message ?? 'Google Drive rejected the upload.');
    } on GoogleSignInException catch (e) {
      // authorizeScopes (the Drive-access consent step, separate from
      // sign-in itself) throws this same exception type when cancelled.
      return UploadError(
        e.code == GoogleSignInExceptionCode.canceled
            ? 'Drive access was cancelled.'
            : e.description ?? 'Google sign-in failed.',
      );
    } catch (e) {
      return UploadError('$e');
    }
  }

  Future<String> _ensureRootFolder(drive.DriveApi api) async {
    final cached = _rootFolderId;
    if (cached != null) return cached;
    final id = await _findOrCreateFolder(
      api,
      name: StorageNames.driveRootFolder,
      parentId: null,
    );
    _rootFolderId = id;
    return id;
  }

  Future<String> _ensureDayFolder(
    drive.DriveApi api,
    String rootFolderId,
    String dayFolderName,
  ) async {
    final cached = _dayFolderIds[dayFolderName];
    if (cached != null) return cached;
    final id = await _findOrCreateFolder(
      api,
      name: dayFolderName,
      parentId: rootFolderId,
    );
    _dayFolderIds[dayFolderName] = id;
    return id;
  }

  Future<String> _findOrCreateFolder(
    drive.DriveApi api, {
    required String name,
    required String? parentId,
  }) async {
    final parentClause = parentId != null ? " and '$parentId' in parents" : '';
    final query = "name = '$name' "
        "and mimeType = 'application/vnd.google-apps.folder' "
        "and trashed = false$parentClause";
    final existing = await api.files.list(
      q: query,
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    final found = existing.files;
    final folderExists = found != null && found.isNotEmpty;
    if (folderExists) {
      return found.first.id!;
    }
    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = parentId != null ? [parentId] : null;
    final created = await api.files.create(folder, $fields: 'id');
    return created.id!;
  }
}
