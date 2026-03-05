import 'dart:async';
import 'package:flutter/material.dart';
import '../services/offline_service.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  Timer? _timer;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _check(); // immediate first check
    // Poll every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  Future<void> _check() async {
    final result = await OfflineService.isOnline();
    if (result != _isOnline) {
      _isOnline = result;
      notifyListeners();
    }
  }

  /// Force a manual re-check (e.g., when user taps "Retry").
  Future<void> recheck() async => _check();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
