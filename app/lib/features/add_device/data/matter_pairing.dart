import '../../../integrations/home_assistant/websocket/ha_websocket_manager.dart';

/// Matter setup codes: the QR payload (`MT:…`) or the 11/21-digit manual
/// pairing code, whose last digit is a Verhoeff check digit.
abstract final class MatterCode {
  static final _qr = RegExp(r'^MT:[0-9A-Z.\-]{8,}$');

  /// Cleaned code, or `null` when it is not a valid Matter code.
  static String? normalize(String input) {
    final trimmed = input.trim();
    if (trimmed.toUpperCase().startsWith('MT:')) {
      final qr = trimmed.toUpperCase();
      return _qr.hasMatch(qr) ? qr : null;
    }
    final digits = trimmed.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^\d+$').hasMatch(digits)) return null;
    if (digits.length != 11 && digits.length != 21) return null;
    return verhoeffValid(digits) ? digits : null;
  }

  static const _d = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];
  static const _p = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  static bool verhoeffValid(String digits) {
    var c = 0;
    final rev = digits.split('').reversed.map(int.parse).toList();
    for (var i = 0; i < rev.length; i++) {
      c = _d[c][_p[i % 8][rev[i]]];
    }
    return c == 0;
  }

  /// Check digit for [digits] (used by tests and the demo hub).
  static int verhoeffDigit(String digits) {
    const inv = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9];
    var c = 0;
    final rev = digits.split('').reversed.map(int.parse).toList();
    for (var i = 0; i < rev.length; i++) {
      c = _d[c][_p[(i + 1) % 8][rev[i]]];
    }
    return inv[c];
  }
}

/// Adds a Matter device that is already on the network (shared from
/// another Matter app) through Home Assistant's Matter integration. Uses
/// the frontend's `matter/commission` WebSocket command (admin only).
class MatterCommissioner {
  MatterCommissioner(this._ws);

  final HaWebSocketManager _ws;

  Future<void> commission(String code) => _ws.sendCommand({
    'type': 'matter/commission',
    'code': code,
    'network_only': true,
  });
}
