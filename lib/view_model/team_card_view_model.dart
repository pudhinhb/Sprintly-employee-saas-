import 'package:flutter/material.dart';
import 'package:webnox_taskops/model/team_card_model.dart';
import 'package:webnox_taskops/view_model/auth_view_model.dart';
import 'package:webnox_taskops/api/api_client.dart';

class TeamCardViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<TeamCard> _cards = [];
  bool _isLoading = false;
  String? _error;

  List<TeamCard> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize team cards for the current user
  Future<void> initialize(AuthViewModel auth) async {
    if (_cards.isEmpty && !_isLoading) {
      await loadCardsForUserRole(auth);
    }
  }

  // Create sample team cards - Disabled or moved to backend
  Future<void> createSampleTeamCards() async {
    // This functionality should be handled by backend seeding
    print('🔧 TeamCardViewModel: Create sample cards disabled in frontend.');
  }

  Future<void> loadCardsForUserRole(AuthViewModel auth) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔍 TeamCardViewModel: Starting to load team cards...');

      final role = await auth.getUserRole();
      final roleNormalized = role?.toLowerCase().trim();
      print(
          '🔍 TeamCardViewModel: User role: $role, normalized: $roleNormalized');

      await _apiClient.init(); // Ensure token is ready

      final queryParams = <String, dynamic>{};
      if (roleNormalized != null) {
        queryParams['role'] = roleNormalized;
      }

      // We assume there is an API endpoint /team-cards that handles filtering by role
      try {
        final response = await _apiClient.get(
          '/employee/team-cards',
          queryParams: queryParams,
          requiresAuth: true,
        );

        if (response.success && response.data != null) {
          final data = response.data;
          _cards = (data as List).map((e) => TeamCard.fromJson(e)).toList();
          print(
              '✅ TeamCardViewModel: Successfully loaded ${_cards.length} team cards');
        } else {
          // If API fails or returns empty, check if we should show empty or error
          // But since API returns success: false for empty (sometimes?) no, API returns success: true and empty list for empty.
          // If it fails:
          if (response.error != null) {
            print('❌ TeamCardViewModel: API Error: ${response.error?.message}');
            _error = response.error?.message;

            // Fallback to empty if not critical
            if (_cards.isEmpty) {
              // Keep empty
            }
          } else {
            _cards = [];
            print('⚠️ TeamCardViewModel: No cards returned from API');
          }
        }
      } catch (e) {
        print('❌ TeamCardViewModel: Error accessing team_cards API: $e');
        _error = 'API error: $e';
      }

      notifyListeners();
    } catch (e) {
      print('❌ TeamCardViewModel: Error loading team cards: $e');
      _error = 'Failed to load team cards: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
