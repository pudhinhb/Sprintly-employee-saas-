import 'dart:convert';
import 'dart:typed_data';
import 'package:webnox_taskops/models/employee_document.dart';
import 'package:webnox_taskops/services/api_config.dart';
import 'package:webnox_taskops/services/file_upload_service.dart';
import 'package:http/http.dart' as http;
import 'package:webnox_taskops/services/local_storage_service.dart';

class EmployeeDocumentService {
  final FileUploadService _fileUploadService = FileUploadService();
  final LocalStorageService _localStorage = LocalStorageService();

  Future<List<EmployeeDocument>> getEmployeeDocuments(String employeeId) async {
    try {
      final token = _localStorage.accessToken;
      // Fixed endpoint to match backend route: /api/employee/requested-documents/<employeeId>
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/employee/requested-documents/$employeeId'),
        headers: ApiConfig.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Handle ApiResponse structure (success: true, data: { employee: ..., documents: [...] })
        if (responseData['success'] == true && responseData['data'] != null) {
          final dynamic data = responseData['data'];

          if (data is Map<String, dynamic> && data.containsKey('documents')) {
            final List<dynamic> docs = data['documents'];
            return docs.map((json) => EmployeeDocument.fromJson(json)).toList();
          } else if (data is List) {
            // Fallback if data is directly the list
            return data.map((json) => EmployeeDocument.fromJson(json)).toList();
          }
          return [];
        } else {
          // Fallback if data is directly the list (legacy support) or empty
          if (responseData is List) {
            return (responseData as List)
                .map((json) => EmployeeDocument.fromJson(json))
                .toList();
          }
          return [];
        }
      } else {
        print(
            'Backend fetch failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      print('Error fetching documents: $e');
      throw Exception('Error fetching documents: $e');
    }
  }

  Future<EmployeeDocument?> submitDocument({
    required String documentId,
    required String employeeId,
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
  }) async {
    try {
      // 1. Upload file to Cloudinary
      final documentUrl = await _fileUploadService.uploadFileWithValidation(
        bytes: fileBytes,
        fileName: fileName,
        fileType: fileType,
      );

      if (documentUrl == null) {
        throw Exception('Failed to upload file to storage');
      }

      // 2. Submit URL to backend
      final token = _localStorage.accessToken;
      // Fixed endpoint to match backend route: /api/employee/submit-document
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/employee/submit-document'),
        headers: ApiConfig.getHeaders(token),
        body: json.encode({
          'documentId': documentId, // Added documentId to body
          'documentUrl': documentUrl,
          'employeeId': employeeId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return EmployeeDocument.fromJson(responseData['data']);
        } else {
          // Fallback if data is directly the object
          return EmployeeDocument.fromJson(responseData);
        }
      } else {
        print(
            'Backend submission failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to submit document to backend');
      }
    } catch (e) {
      print('Error submitting document: $e');
      throw Exception('Error submitting document: $e');
    }
  }
}
