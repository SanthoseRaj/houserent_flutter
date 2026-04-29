import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

String? _resolveMimeType(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == fileName.length - 1) {
    return null;
  }

  switch (fileName.substring(dotIndex + 1).toLowerCase()) {
    case 'jpg':
    case 'jpeg':
    case 'jpe':
    case 'jfif':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'bmp':
      return 'image/bmp';
    case 'avif':
      return 'image/avif';
    case 'tif':
    case 'tiff':
      return 'image/tiff';
    case 'heic':
      return 'image/heic';
    case 'heif':
      return 'image/heif';
    case 'svg':
      return 'image/svg+xml';
    case 'ico':
      return 'image/x-icon';
    case 'pdf':
      return 'application/pdf';
    default:
      return null;
  }
}

Future<MultipartFile> platformFileToMultipartFile(PlatformFile file) async {
  final mimeType = _resolveMimeType(file.name);
  final contentType = mimeType == null ? null : DioMediaType.parse(mimeType);

  final bytes = file.bytes;
  if (bytes != null) {
    return MultipartFile.fromBytes(
      bytes,
      filename: file.name,
      contentType: contentType,
    );
  }

  final path = file.path;
  if (path != null && path.isNotEmpty) {
    return MultipartFile.fromFile(
      path,
      filename: file.name,
      contentType: contentType,
    );
  }

  throw Exception(
    'Selected file "${file.name}" cannot be uploaded. Please choose it again.',
  );
}
