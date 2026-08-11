import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/elderly_mode_provider.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_action_handler.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'features/authentication/providers/auth_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/settings/data/settings_models.dart';
import 'features/settings/providers/theme_mode_provider.dart';
import 'features/splash/presentation/screens/animated_splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  await NotificationService.instance.initialize();
  NotificationActionHandler.register();

  // Module 15: covers the "app stays open and reconnects mid-session"
  // case for auto-sync — the opportunistic sync in TodayDosesController
  // .load() only covers "user reopens/refreshes after being offline".
  ConnectivityService.instance.onStatusChange.listen((isOnline) {
    if (isOnline) {
      SyncService.instance.syncPendingActions();
    }
  });

  runApp(const ProviderScope(child: SmartMedsApp()));
}

class SmartMedsApp extends ConsumerWidget {
  const SmartMedsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final appThemeMode = ref.watch(themeModeProvider);

    // Elderly Mode's high-contrast light theme always wins when enabled
    // — the two settings aren't designed to compose (see the README's
    // Module 16 note on why "dark elderly mode" wasn't built out).
    final ThemeData activeTheme;
    final ThemeMode flutterThemeMode;
    if (isElderlyMode) {
      activeTheme = AppTheme.elderly();
      flutterThemeMode = ThemeMode.light;
    } else {
      switch (appThemeMode) {
        case AppThemeMode.light:
          activeTheme = AppTheme.standard();
          flutterThemeMode = ThemeMode.light;
        case AppThemeMode.dark:
          activeTheme = AppTheme.dark();
          flutterThemeMode = ThemeMode.dark;
        case AppThemeMode.system:
          activeTheme = AppTheme.standard();
          flutterThemeMode = ThemeMode.system;
      }
    }

    return MaterialApp(
      title: 'SmartMeds',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      darkTheme: AppTheme.dark(),
      themeMode: flutterThemeMode,
      // Module 13's "Large Font" needs to apply even to the many screens
      // built with hardcoded TextStyle(fontSize: ...) rather than
      // Theme.of(context).textTheme — ThemeData.textTheme scaling alone
      // wouldn't reach those. MediaQuery's textScaler applies at the
      // render layer to every Text widget app-wide regardless, so it's
      // the actual mechanism doing most of the work here; the theme
      // change above still matters for colors and button sizing.
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(isElderlyMode ? 1.3 : 1.0),
          ),
          child: child!,
        );
      },
      home: const AnimatedSplashScreen(),
    );
  }
}

/// Reads the persisted Supabase session on launch.
/// Supabase's local storage keeps the session across app restarts by
/// default, which is what gives us "Remember Login" for free — no
/// extra flag or shared_preferences needed.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const LoginScreen(),
      data: (authState) {
        final isLoggedIn = ref.watch(isLoggedInProvider);
        return isLoggedIn ? const DashboardScreen() : const LoginScreen();
      },
    );
  }
}