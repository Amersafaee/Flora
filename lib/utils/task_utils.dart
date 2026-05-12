DateTime? calculateNextDueDate(DateTime currentDue, String repeatType, [int repeatDays = 7]) {
  if (repeatType == 'none' || repeatType.isEmpty) {
    return null;
  }

  switch (repeatType) {
    case 'daily':
      return currentDue.add(const Duration(days: 1));
    case 'every2days':
      return currentDue.add(const Duration(days: 2));
    case 'weekly':
      return currentDue.add(const Duration(days: 7));
    case 'biweekly':
      return currentDue.add(const Duration(days: 14));
    case 'monthly':
      return DateTime(currentDue.year, currentDue.month + 1, currentDue.day);
    default:
      return currentDue.add(Duration(days: repeatDays));
  }
}
