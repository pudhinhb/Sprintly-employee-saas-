import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class APIResponse {
  final bool status;
  final String message;
  final dynamic response;

  APIResponse(
      {required this.status, required this.message, required this.response});
}

// Cloudinary constants
const String cloudinaryCloudName = 'dnkdrre1g';
const String cloudinaryAPIKey = '372636514621377';
const String cloudinaryAPISecretKey = 'mvTJg_ksWnhbcJoxCSIpZZcgO_I';
const String CLOUDINARY_URL =
    'cloudinary://$cloudinaryAPIKey:$cloudinaryAPISecretKey@dnkdrre1g';

class CloudinaryService {
  static Future<APIResponse> uploadFileToBucket({
    required PlatformFile? file,
  }) async {
    if (file == null || file.size == 0) {
      return APIResponse(
          status: false, message: 'No file picked to upload.', response: '');
    }

    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/auto/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = 'flutter_unsigned_upload';
      request.fields['folder'] = 'taskOps-employee';

      // Prepare multipart file for web and mobile/desktop
      if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
        request.files
            .add(await http.MultipartFile.fromPath('file', file.path!));
      } else if (file.bytes != null) {
        final String filename = file.name;
        final MediaType contentType = _lookupMediaType(filename);
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: filename,
          contentType: contentType,
        ));
      } else {
        return APIResponse(
            status: false,
            message: 'Missing file bytes/path for upload.',
            response: '');
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final url = RegExp('"secure_url"\s*:\s*"(.*?)"')
            .firstMatch(response.body)
            ?.group(1);
        if (url != null && url.isNotEmpty) {
          return APIResponse(
            status: true,
            message: 'File uploaded successfully.',
            response: url,
          );
        }
      }

      return APIResponse(
        status: false,
        message:
            'Server error ${response.statusCode}, Could not upload the file.',
        response: '',
      );
    } catch (e) {
      return APIResponse(
        status: false,
        message: 'Upload failed: $e',
        response: '',
      );
    }
  }

  static MediaType _lookupMediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'gif':
        return MediaType('image', 'gif');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'json':
        return MediaType('application', 'json');
      case 'txt':
        return MediaType('text', 'plain');
      case 'apk':
        return MediaType('application', 'vnd.android.package-archive');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
