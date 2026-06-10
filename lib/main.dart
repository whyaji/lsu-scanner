import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/regional/screens/regional_selection_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/lsu_home_screen.dart';
import 'features/home/screens/fertilizer_home_screen.dart';
import 'features/home/screens/bottom_nav_shell.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/regional/providers/regional_provider.dart';
import 'features/settings/providers/theme_provider.dart';
import 'core/network/services/app_update_service.dart';
import 'core/network/services/fcm_service.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'features/notifications/providers/notification_provider.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(AppConstants.uiDateLocale);

  await dotenv.load(fileName: '.env');
  await AppConstants.init();

  // Request permissions
  await _requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.storage,
    Permission.photos,
    Permission.notification,
  ].request();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).themeMode;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        ref.read(fcmServiceProvider).uploadToken();
        ref
            .read(notificationProvider.notifier)
            .fetchNotifications(silent: true);
      }

      if (!next.shouldNavigateToLogin) return;
      void tryNavigate(int attempt) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = appNavigatorKey.currentState;
          if (nav != null) {
            nav.pushNamedAndRemoveUntil('/login', (_) => false);
            ref
                .read(authProvider.notifier)
                .acknowledgeSessionTerminatedNavigation();
          } else if (attempt < 30) {
            tryNavigate(attempt + 1);
          }
        });
      }

      tryNavigate(0);
    });

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale(AppConstants.uiDateLocale),
      supportedLocales: const [Locale(AppConstants.uiDateLocale)],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/regional': (context) => const RegionalSelectionScreen(),
        '/home': (context) => const HomeScreen(),
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appUpdateCheckProvider);
    final authState = ref.watch(authProvider);
    final regionalState = ref.watch(regionalProvider);

    // Check authentication
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // Initialize FCM when authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).init();
    });

    // Check regional selection
    if (regionalState.selectedRegional == null) {
      return const RegionalSelectionScreen();
    }

    // Dual module → bottom nav. Single module → dedicated home.
    final user = authState.user;
    final hasLsu = user?.hasAnyLsuMobileAccess ?? false;
    final hasPupuk = user?.hasAnyPupukMobileAccess ?? false;

    if (hasLsu && hasPupuk) {
      return const BottomNavShell();
    }
    if (hasLsu) {
      return const LsuHomeScreen(showBackButton: false);
    }
    if (hasPupuk) {
      return const FertilizerHomeScreen(showBackButton: false);
    }
    return const HomeScreen();
  }
}
