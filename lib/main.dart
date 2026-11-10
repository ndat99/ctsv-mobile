import 'package:flutter/material.dart';

import 'app/ctsv_app.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CtsvApp(config: AppConfig.fromEnvironment()));
}
