import '../services/local_storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _localStorage = LocalStorageService();

  bool get isLoggedIn {
    return _localStorage.isLoggedIn;
  }

  String get accessToken => _localStorage.accessToken;

  String get userId => _localStorage.userId;

  String get emailId => _localStorage.emailId;
}
