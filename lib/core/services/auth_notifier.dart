import 'package:flutter/foundation.dart';
import 'pocketbase_service.dart';

class AuthChangeNotifier extends ChangeNotifier {
  final PocketBaseService _pbService;

  AuthChangeNotifier(this._pbService) {
    _pbService.client.authStore.onChange.listen((_) {
      notifyListeners();
    });
  }

  bool get isAuthenticated => _pbService.isAuthenticated;
}