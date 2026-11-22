import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import 'bookings_screen.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart';

/// Навигация по нижним вкладкам + сигнал «покажи мои записи» после успешного бронирования.
class AppShellController extends ChangeNotifier {
  int _tab = 0;
  int _bookingsVersion = 0;

  int get tab => _tab;
  int get bookingsVersion => _bookingsVersion;

  void select(int index) {
    if (_tab == index) {
      return;
    }
    _tab = index;
    notifyListeners();
  }

  void openBookings() {
    _tab = 1;
    _bookingsVersion++;
    notifyListeners();
  }

  void reset() {
    if (_tab != 0) {
      _tab = 0;
      notifyListeners();
    }
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppShellController>().reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppShellController>();

    final pages = [
      const CatalogScreen(),
      BookingsScreen(key: ValueKey('bookings-${controller.bookingsVersion}')),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[controller.tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.tab,
        onDestinationSelected: controller.select,
        backgroundColor: Colors.white,
        indicatorColor: kSeed.withValues(alpha: 0.14),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: kSeed),
            label: 'Каталог',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded, color: kSeed),
            label: 'Записи',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: kSeed),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
