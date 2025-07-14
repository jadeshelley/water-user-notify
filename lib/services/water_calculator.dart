class WaterCalculator {
  static double calculateSprinklerHeads({
    required double rate,
    required double sharesOfWater,
    required int hoursInPeriod,
  }) {
    // Formula: (Rate# * 3 * SharesOfWaterUser) / hours in period
    return (rate * 3 * sharesOfWater) / hoursInPeriod;
  }

  static double calculateFor12HourPeriod({
    required double rate,
    required double sharesOfWater,
  }) {
    return calculateSprinklerHeads(
      rate: rate,
      sharesOfWater: sharesOfWater,
      hoursInPeriod: 12,
    );
  }

  static double calculateFor24HourPeriod({
    required double rate,
    required double sharesOfWater,
  }) {
    return calculateSprinklerHeads(
      rate: rate,
      sharesOfWater: sharesOfWater,
      hoursInPeriod: 24,
    );
  }

  static String formatSprinklerHeads(double sprinklerHeads) {
    // Round to 2 decimal places for display
    return sprinklerHeads.toStringAsFixed(2);
  }

  static String generateNotificationMessage({
    required String userName,
    required double sprinklerHeads,
    required int hoursInPeriod,
  }) {
    return '''
Water Usage Notification for $userName

You can use ${formatSprinklerHeads(sprinklerHeads)} sprinkler heads during the ${hoursInPeriod}-hour period.

This calculation is based on your water shares and the current rate setting.
''';
  }
} 