import 'package:flutter/foundation.dart';

import '../../../core/network/server_address.dart';
import '../../../core/network/tls_trust.dart';

/// Non-secret description of the connected server. Persisted in
/// preferences; the access token is stored separately in secure storage.
@immutable
class ServerProfile {
  const ServerProfile({
    required this.address,
    this.pinnedCertificateSha256,
    this.insecureConnectionAcknowledged = false,
  });

  /// Returns `null` for missing or invalid stored data.
  static ServerProfile? tryFromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final url = json['url'];
    if (url is! String) return null;
    final parsed = ServerAddress.parse(url);
    if (parsed is! ValidServerAddress) return null;
    final pin = json['pinnedCertificateSha256'];
    return ServerProfile(
      address: parsed.address,
      pinnedCertificateSha256: pin is String ? pin : null,
      insecureConnectionAcknowledged:
          json['insecureConnectionAcknowledged'] == true,
    );
  }

  final ServerAddress address;

  /// Fingerprint of a self-signed certificate the user explicitly trusted.
  final String? pinnedCertificateSha256;

  /// The user confirmed they understand the risk of plain HTTP to a
  /// non-local address (e.g. because traffic runs through a VPN).
  final bool insecureConnectionAcknowledged;

  String get id => address.id;

  TlsTrust get tlsTrust => TlsTrust(pinnedSha256: pinnedCertificateSha256);

  Map<String, Object?> toJson() => {
    'url': address.baseUri.toString(),
    'pinnedCertificateSha256': pinnedCertificateSha256,
    'insecureConnectionAcknowledged': insecureConnectionAcknowledged,
  };

  @override
  bool operator ==(Object other) =>
      other is ServerProfile &&
      other.address == address &&
      other.pinnedCertificateSha256 == pinnedCertificateSha256 &&
      other.insecureConnectionAcknowledged == insecureConnectionAcknowledged;

  @override
  int get hashCode => Object.hash(
    address,
    pinnedCertificateSha256,
    insecureConnectionAcknowledged,
  );
}
