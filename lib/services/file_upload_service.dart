import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'local_storage_service.dart';

class FileUploadService {
  final LocalStorageService _localStorage = LocalStorageService();

  /// Upload a file via the Backend Proxy (which uses Signed Cloudinary uploads)
  /// Returns the public URL if successful, null if failed
  Future<String?> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String fileType,
  }) async {
    try {
      print(
          '🔄 FileUploadService: Proxying upload through backend for $fileName');

      final token = _localStorage.accessToken;
      // Backend endpoint: POST /api/uploadFileToBucket
      final uploadUrl = Uri.parse('${ApiConfig.baseUrl}/uploadFileToBucket');

      final request = http.MultipartRequest('POST', uploadUrl);

      // Add Authorization Header
      request.headers.addAll(ApiConfig.getHeaders(token));

      // Add file data
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      // Optional: Add folder param
      request.fields['folder'] = 'sprintly_documents';

      print(
          '📤 FileUploadService: Sending multipart request to ${uploadUrl.toString()}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
          '📥 FileUploadService: Backend response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Handle ApiResponse structure (success: true, data: { url: ... })
        if (responseData['success'] == true && responseData['data'] != null) {
          final publicUrl = responseData['data']['url'] as String?;
          print('✅ FileUploadService: Upload successful! URL: $publicUrl');
          return publicUrl;
        } else {
          print(
              '❌ FileUploadService: Backend reported failure: ${responseData['message']}');
          return null;
        }
      } else {
        print(
            '❌ FileUploadService: Backend error status ${response.statusCode}');
        print('  - Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ FileUploadService: Error during backend proxy upload: $e');
      return null;
    }
  }

  /// Upload multiple files and return their URLs
  Future<List<String>> uploadFiles({
    required List<Uint8List> filesBytes,
    required List<String> fileNames,
    required List<String> fileTypes,
  }) async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < filesBytes.length; i++) {
      final url = await uploadFile(
        bytes: filesBytes[i],
        fileName: fileNames[i],
        fileType: fileTypes[i],
      );

      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  /// Validate file before upload
  bool _validateFile(Uint8List bytes, String fileName, String fileType) {
    // Check file size (max 10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (bytes.length > maxSize) {
      print('❌ FileUploadService: File too large (${bytes.length} bytes)');
      return false;
    }

    // Check file type - Backend permits more but let's sync basic restricted list
    final allowedExtensions = [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'txt',
      'csv',
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
    ];

    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      print('❌ FileUploadService: Unsupported file extension: $extension');
      return false;
    }

    return true;
  }

  /// Upload file with validation
  Future<String?> uploadFileWithValidation({
    required Uint8List bytes,
    required String fileName,
    required String fileType,
  }) async {
    if (!_validateFile(bytes, fileName, fileType)) {
      return null;
    }

    return await uploadFile(
      bytes: bytes,
      fileName: fileName,
      fileType: fileType,
    );
  }
}
