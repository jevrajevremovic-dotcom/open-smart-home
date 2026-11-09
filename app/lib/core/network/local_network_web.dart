import 'local_network.dart';

LocalNetwork createLocalNetwork() => _WebNetwork();

class _WebNetwork implements LocalNetwork {
  @override
  Future<bool?> hasNetwork() async => null;

  @override
  bool get canWake => false;

  @override
  Future<void> wake(List<int> mac) =>
      throw UnsupportedError('No UDP in the browser');
}
