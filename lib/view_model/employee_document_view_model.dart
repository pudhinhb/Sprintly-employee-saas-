import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:webnox_taskops/models/employee_document.dart';
import 'package:webnox_taskops/services/employee_document_service.dart';

class EmployeeDocumentViewModel extends ChangeNotifier {
  final EmployeeDocumentService _service = EmployeeDocumentService();
  List<EmployeeDocument> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<EmployeeDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDocuments(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _documents = await _service.getEmployeeDocuments(employeeId);
      _documents.sort((a, b) {
        // Sort by created date descending
        return b.createdAt.compareTo(a.createdAt);
      });
    } catch (e) {
      _error = e.toString();
      _documents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadDocument({
    required String documentId,
    required String employeeId,
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedDoc = await _service.submitDocument(
        documentId: documentId,
        employeeId: employeeId,
        fileBytes: fileBytes,
        fileName: fileName,
        fileType: fileType,
      );

      if (updatedDoc != null) {
        // Update local list
        final index = _documents.indexWhere((d) => d.id == documentId);
        if (index != -1) {
          _documents[index] = updatedDoc;
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
