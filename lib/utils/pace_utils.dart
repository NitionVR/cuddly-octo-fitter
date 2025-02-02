class PaceUtils {
  /// Converts pace string (e.g., "5:30 min/km") to seconds
  static int paceStringToSeconds(String paceStr) {
    try {
      // Remove "min/km" and trim
      final timeStr = paceStr.split(' ')[0].trim();
      final parts = timeStr.split(':');

      if (parts.length != 2) return 0;

      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;

      return (minutes * 60) + seconds;
    } catch (e) {
      print('Error converting pace string to seconds: $e');
      return 0;
    }
  }

  /// Converts seconds to pace string (e.g., "5:30 min/km")
  static String secondsToPaceString(int seconds) {
    try {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')} min/km';
    } catch (e) {
      print('Error converting seconds to pace string: $e');
      return '0:00 min/km';
    }
  }

  /// Calculates pace in seconds from distance (meters) and duration (seconds)
  static int calculatePaceSeconds(double distanceMeters, int durationSeconds) {
    try {
      if (distanceMeters <= 0 || durationSeconds <= 0) return 0;

      final distanceKm = distanceMeters / 1000;
      return (durationSeconds / distanceKm).round();
    } catch (e) {
      print('Error calculating pace: $e');
      return 0;
    }
  }

  /// Formats pace for display with optional units
  static String formatPace(int paceSeconds, {bool includeUnits = true}) {
    try {
      final minutes = paceSeconds ~/ 60;
      final seconds = paceSeconds % 60;
      final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
      return includeUnits ? '$timeStr min/km' : timeStr;
    } catch (e) {
      print('Error formatting pace: $e');
      return includeUnits ? '0:00 min/km' : '0:00';
    }
  }

  /// Calculates average pace from multiple pace values
  static int calculateAveragePaceSeconds(List<int> pacesInSeconds) {
    try {
      if (pacesInSeconds.isEmpty) return 0;

      final sum = pacesInSeconds.reduce((a, b) => a + b);
      return (sum / pacesInSeconds.length).round();
    } catch (e) {
      print('Error calculating average pace: $e');
      return 0;
    }
  }

  /// Validates if a pace string is in correct format
  static bool isValidPaceString(String paceStr) {
    try {
      final pattern = RegExp(r'^\d{1,2}:\d{2}\s*(?:min/km)?$');
      return pattern.hasMatch(paceStr.trim());
    } catch (e) {
      print('Error validating pace string: $e');
      return false;
    }
  }

  /// Compares two paces (in seconds) and returns the difference
  static int comparePaces(int pace1Seconds, int pace2Seconds) {
    return pace1Seconds - pace2Seconds;
  }

  /// Converts pace to speed (km/h)
  static double paceToSpeed(int paceSeconds) {
    try {
      if (paceSeconds <= 0) return 0;
      return 3600 / paceSeconds; // 3600 seconds in an hour
    } catch (e) {
      print('Error converting pace to speed: $e');
      return 0;
    }
  }

  /// Converts speed (km/h) to pace (seconds per km)
  static int speedToPace(double speedKmh) {
    try {
      if (speedKmh <= 0) return 0;
      return (3600 / speedKmh).round();
    } catch (e) {
      print('Error converting speed to pace: $e');
      return 0;
    }
  }
}