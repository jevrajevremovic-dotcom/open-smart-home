import 'package:flutter/foundation.dart';

/// Electricity price entered by the user, used only for a clearly labelled
/// cost *estimate* (real bills include fixed fees, taxes, time-of-use
/// rates…).
@immutable
class Tariff {
  const Tariff({
    required this.importPrice,
    this.exportPrice,
    this.currency = 'RSD',
  });

  static Tariff? tryFromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final import = json['importPrice'];
    if (import is! num || import < 0) return null;
    final export = json['exportPrice'];
    final currency = json['currency'];
    return Tariff(
      importPrice: import.toDouble(),
      exportPrice: export is num && export >= 0 ? export.toDouble() : null,
      currency: currency is String && currency.isNotEmpty ? currency : 'RSD',
    );
  }

  /// Price per kWh taken from the grid.
  final double importPrice;

  /// Compensation per kWh returned to the grid, if any.
  final double? exportPrice;
  final String currency;

  /// `null` when the grid import is unknown.
  double? estimate({required double? gridImport, double? gridExport}) {
    if (gridImport == null) return null;
    return gridImport * importPrice - (gridExport ?? 0) * (exportPrice ?? 0);
  }

  Map<String, Object?> toJson() => {
    'importPrice': importPrice,
    'exportPrice': exportPrice,
    'currency': currency,
  };
}
