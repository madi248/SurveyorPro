import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: NavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          indicatorColor: Colors.transparent, // Disable standard indicator
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => _onTap(context, index),
          destinations: [
            _buildDestination(Icons.grid_view_outlined, 'Dashboard', 0),
            _buildDestination(Icons.calculate_outlined, 'Calc', 1),
            _buildDestination(Icons.map_outlined, 'Map', 2),
            _buildDestination(Icons.settings_outlined, 'Settings', 3),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildDestination(IconData icon, String label, int index) {
    // final isSelected = navigationShell.currentIndex == index;
    // We custom build the icon to match the React styling (Text color change)
    // React prototype uses primary color for text and icon when active.
    return NavigationDestination(
      icon: Icon(icon, color: Colors.grey),
      selectedIcon: Icon(icon, color: const Color(0xFF135BEC)), // Primary
      label: label,
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
