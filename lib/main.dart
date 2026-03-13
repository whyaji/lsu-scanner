import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/regional/screens/regional_selection_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/lsu_home_screen.dart';
import 'features/home/screens/fertilizer_home_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/regional/providers/regional_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await AppConstants.init();

  // Request permissions
  await _requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestPermissions() async {
  await [Permission.camera, Permission.storage, Permission.photos].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/regional': (context) => const RegionalSelectionScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final regionalState = ref.watch(regionalProvider);

    // Check authentication
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // Check regional selection
    if (regionalState.selectedRegional == null) {
      return const RegionalSelectionScreen();
    }

    // Default home by access: only LSU → LsuHomeScreen; only pupuk → FertilizerHomeScreen; both → HomeScreen
    final access = authState.user?.access;
    final hasLsu = access != null && access.contains('lsu');
    final hasPupuk = authState.user?.hasAnyPupukAccess ?? false;

    if (hasLsu && hasPupuk) {
      return const HomeScreen();
    }
    if (hasLsu) {
      return const LsuHomeScreen();
    }
    if (hasPupuk) {
      return const FertilizerHomeScreen();
    }
    return const HomeScreen();
  }
}
