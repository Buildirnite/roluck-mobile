import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/editor')) return 1;
    if (location.startsWith('/lote')) return 2;
    if (location.startsWith('/pdf')) return 3;
    if (location.startsWith('/mas')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          const routes = ['/', '/editor', '/lote', '/pdf', '/mas'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            selectedIcon: Icon(Icons.swap_horiz, color: AppColors.accent),
            label: 'Convertir',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit),
            selectedIcon: Icon(Icons.edit, color: AppColors.accent),
            label: 'Editor',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers),
            selectedIcon: Icon(Icons.layers, color: AppColors.accent),
            label: 'Lote',
          ),
          NavigationDestination(
            icon: Icon(Icons.picture_as_pdf),
            selectedIcon: Icon(Icons.picture_as_pdf, color: AppColors.accent),
            label: 'A PDF',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps),
            selectedIcon: Icon(Icons.apps, color: AppColors.accent),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}
