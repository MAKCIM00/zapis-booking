import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/auth_state.dart';
import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZapisApp());
}

class ZapisApp extends StatefulWidget {
  const ZapisApp({super.key});

  @override
  State<ZapisApp> createState() => _ZapisAppState();
}

class _ZapisAppState extends State<ZapisApp> {
  late final ApiClient _api = ApiClient();
  late final AuthState _auth = AuthState(_api);
  late final AppShellController _shell = AppShellController();

  @override
  void initState() {
    super.initState();
    _auth.restore();
  }

  @override
  void dispose() {
    _auth.dispose();
    _shell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _api),
        ChangeNotifierProvider<AuthState>.value(value: _auth),
        ChangeNotifierProvider<AppShellController>.value(value: _shell),
      ],
      child: MaterialApp(
        title: 'Аура — запись онлайн',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.restoring) {
      return const _SplashScreen();
    }
    return auth.isAuthorized ? const HomeShell() : const LoginScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C4DF6), Color(0xFF9B72FF)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.content_cut_rounded, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text(
                'Аура',
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
