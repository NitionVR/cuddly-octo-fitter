class PersonalRecord {
  final String category; // e.g., "5K", "10K", "Longest Run"
  final double value;
  final DateTime achievedDate;
  final String displayValue;

  PersonalRecord({
    required this.category,
    required this.value,
    required this.achievedDate,
    required this.displayValue,
  });
}