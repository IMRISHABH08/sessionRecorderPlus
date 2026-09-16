import 'package:equatable/equatable.dart';

sealed class UploadStatus extends Equatable {
  const UploadStatus();
}

class UploadIdle extends UploadStatus {
  const UploadIdle();

  @override
  List<Object?> get props => [];
}

class UploadNotSignedIn extends UploadStatus {
  const UploadNotSignedIn();

  @override
  List<Object?> get props => [];
}

class UploadInProgress extends UploadStatus {
  const UploadInProgress();

  @override
  List<Object?> get props => [];
}

class UploadSuccess extends UploadStatus {
  const UploadSuccess({required this.fileLinks});

  final List<String> fileLinks;

  @override
  List<Object?> get props => [fileLinks];
}

class UploadError extends UploadStatus {
  const UploadError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
