import 'dart:math';

/// Service to manage daily quotes
/// Provides one quote per day from a collection of 20 quotes
class DailyQuoteService {
  static final DailyQuoteService _instance = DailyQuoteService._internal();
  factory DailyQuoteService() => _instance;
  DailyQuoteService._internal();

  // Collection of 20 inspirational quotes
  static const List<String> _quotes = [
    "The only way to do great work is to love what you do.",
    "Innovation distinguishes between a leader and a follower.",
    "Don't be afraid to give up the good to go for the great.",
    "The future belongs to those who believe in the beauty of their dreams.",
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "The way to get started is to quit talking and begin doing.",
    "Don't let yesterday take up too much of today.",
    "You learn more from failure than from success.",
    "If you are working on something exciting that you really care about, you don't have to be pushed. The vision pulls you.",
    "People who are crazy enough to think they can change the world, are the ones who do.",
    "We may encounter many defeats but we must not be defeated.",
    "The only limit to our realization of tomorrow will be our doubts of today.",
    "It's not whether you get knocked down, it's whether you get up.",
    "The greatest glory in living lies not in never falling, but in rising every time we fall.",
    "In the middle of difficulty lies opportunity.",
    "The only person you are destined to become is the person you decide to be.",
    "Go confidently in the direction of your dreams. Live the life you have imagined.",
    "The two most important days in your life are the day you are born and the day you find out why.",
    "Whatever you can do, or dream you can, begin it. Boldness has genius, power and magic in it.",
    "The best time to plant a tree was 20 years ago. The second best time is now.",
  ];

  /// Get today's quote based on the day of the year
  /// This ensures the same quote appears throughout the day
  String getTodaysQuote() {
    final now = DateTime.now();
    // Use day of year (1-365/366) to cycle through quotes
    // This ensures the same quote appears all day
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final quoteIndex = dayOfYear % _quotes.length;
    return '"${_quotes[quoteIndex]}"';
  }

  /// Get a random quote (for testing or special cases)
  String getRandomQuote() {
    final random = Random();
    return '"${_quotes[random.nextInt(_quotes.length)]}"';
  }

  /// Get all quotes
  List<String> getAllQuotes() {
    return List.unmodifiable(_quotes);
  }
}

