import 'package:flutter/foundation.dart';

import '../domain/training_management_config.dart';

class TrainingManagementStore extends ChangeNotifier {
  TrainingManagementStore._();

  static final TrainingManagementStore instance = TrainingManagementStore._();

  TrainingManagementConfig _config = TrainingManagementConfig.defaults();

  TrainingManagementConfig get config => _config;

  void update(TrainingManagementConfig next) {
    _config = next;
    notifyListeners();
  }

  void reset() {
    _config = TrainingManagementConfig.defaults();
    notifyListeners();
  }
}
