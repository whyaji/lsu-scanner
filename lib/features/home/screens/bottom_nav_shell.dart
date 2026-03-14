import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../auth/providers/auth_provider.dart';
import 'lsu_home_screen.dart';
import 'fertilizer_home_screen.dart';
import '../../settings/screens/settings_screen.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Shell with bottom navigation. Destinations depend on user access:
/// - LSU tab if user has 'lsu' access
/// - Pupuk tab if user has any access starting with 'pupuk' (e.g. pupuk:estate, pupuk:nt)
/// - Upload and Settings always shown.
class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final access = authState.user?.access;
    final hasLsu = access != null && access.contains('lsu');
    final hasPupuk = authState.user?.hasAnyPupukAccess ?? false;

    final destinations = <NavigationDestination>[];
    final children = <Widget>[];

    if (hasLsu) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.eco_outlined),
          selectedIcon: Icon(Icons.eco),
          label: 'LSU',
        ),
      );
      children.add(
        const LsuHomeScreen(showBackButton: false, showSettingsInAppBar: false),
      );
    }

    if (hasPupuk) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.science_outlined),
          selectedIcon: Icon(Icons.science),
          label: 'Pupuk',
        ),
      );
      children.add(
        const FertilizerHomeScreen(
          showBackButton: false,
          showSettingsInAppBar: false,
        ),
      );
    }

    destinations.add(
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Pengaturan',
      ),
    );
    children.add(const SettingsScreen(showBackButton: false));

    var index = ref.watch(bottomNavIndexProvider);
    if (index >= children.length) {
      index = children.isNotEmpty ? children.length - 1 : 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bottomNavIndexProvider.notifier).state = index;
      });
    }

    return Scaffold(
      body: IndexedStack(index: index, children: children),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          ref.read(bottomNavIndexProvider.notifier).state = i;
        },
        destinations: destinations,
      ),
    );
  }
}
