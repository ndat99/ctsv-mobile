import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/data/session_store.dart';
import '../features/auth/presentation/login_page.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';

class CtsvApp extends StatefulWidget {
  const CtsvApp({super.key, required this.config, this.auth});

  final AppConfig config;
  final AuthController? auth;

  @override
  State<CtsvApp> createState() => _CtsvAppState();
}

class _CtsvAppState extends State<CtsvApp> {
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth =
        widget.auth ??
        AuthController(
          AuthService(
            api: ApiClient(config: widget.config),
            store: const SecureSessionStore(),
          ),
        );
    unawaited(_auth.restore());
  }

  @override
  void dispose() {
    if (widget.auth == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CTSV DUT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ListenableBuilder(
        listenable: _auth,
        builder: (context, _) => switch (_auth.status) {
          AuthStatus.restoring => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          AuthStatus.signedOut => LoginPage(auth: _auth),
          AuthStatus.restoreFailed => Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Chưa thể khôi phục phiên đăng nhập'),
                      const SizedBox(height: 12),
                      Text(_auth.message ?? '', textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _auth.restore,
                        child: const Text('Thử lại'),
                      ),
                      TextButton(
                        onPressed: _auth.busy ? null : _auth.logout,
                        child: const Text('Đăng nhập lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AuthStatus.signedIn => AppShell(
            key: ValueKey(_auth.user!.id),
            auth: _auth,
          ),
        },
      ),
    );
  }
}
