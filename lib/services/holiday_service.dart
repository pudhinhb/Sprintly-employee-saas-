import 'package:webnox_taskops/api/endpoints/holiday_api.dart';

class HolidayService {
  final _api = HolidayApi();

  /// Fetch all holidays
  Future<List<Map<String, dynamic>>> getAllHolidays() async {
    try {
      final response = await _api.getAllHolidays();
      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      return [];
    } catch (e) {
      print('Error fetching holidays: $e');
      return [];
    }
  }

  /// Fetch holidays for a specific month
  Future<List<Map<String, dynamic>>> getHolidaysForMonth({
    required int year,
    required int month,
  }) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0);

      final response = await _api.getHolidays(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      return [];
    } catch (e) {
      print('Error fetching holidays for month: $e');
      return [];
    }
  }

  /// Fetch holidays for a specific date range
  Future<List<Map<String, dynamic>>> getHolidaysForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _api.getHolidays(
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      return [];
    } catch (e) {
      print('Error fetching holidays for date range: $e');
      return [];
    }
  }

  /// Check if a specific date is a holiday
  Future<bool> isHoliday(DateTime date) async {
    try {
      final response = await _api.getHolidayForDate(date);
      if (response.success && response.data != null) {
        final data = response.data as List;
        return data.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking if date is holiday: $e');
      return false;
    }
  }

  /// Get holiday details for a specific date
  Future<Map<String, dynamic>?> getHolidayForDate(DateTime date) async {
    try {
      final response = await _api.getHolidayForDate(date);
      if (response.success && response.data != null) {
        final data = response.data as List;
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting holiday for date: $e');
      return null;
    }
  }

  /// Get upcoming holidays (next 30 days)
  Future<List<Map<String, dynamic>>> getUpcomingHolidays() async {
    try {
      final today = DateTime.now();
      final thirtyDaysFromNow = today.add(const Duration(days: 30));

      final response = await _api.getHolidays(
        startDate: today,
        endDate: thirtyDaysFromNow,
      );

      if (response.success && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      return [];
    } catch (e) {
      print('Error fetching upcoming holidays: $e');
      return [];
    }
  }
}
