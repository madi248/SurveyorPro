import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/projects/presentation/project_selection_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/computation/presentation/computation_hub_screen.dart';
import 'features/computation/presentation/traverse_screen.dart';
import 'features/computation/presentation/cogo_screen.dart';
import 'features/computation/presentation/leveling_screen.dart';
import 'features/leveling/presentation/leveling_dashboard_screen.dart';
import 'features/leveling/presentation/leveling_book_screen.dart';
import 'features/map/presentation/map_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/settings/presentation/device_connection_screen.dart';
import 'features/field_log/presentation/field_log_screen.dart';
import 'features/import/presentation/import_screen.dart';
import 'shared/widgets/scaffold_with_navbar.dart';

void main() {
  runApp(const SurveyorProApp());
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
    final activeProjectId = prefs.getInt('active_project_id');
    
    // If user has completed onboarding and has active project, go to dashboard
    if (hasCompletedOnboarding && activeProjectId != null && state.matchedLocation == '/onboarding') {
      return '/dashboard';
    }
    
    return null; // No redirect
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/projects',
      builder: (context, state) => const ProjectSelectionScreen(),
    ),
    GoRoute(
      path: '/field_log',
      builder: (context, state) => const FieldLogScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'import',
                  builder: (context, state) {
                    final projectId = int.parse(state.uri.queryParameters['projectId'] ?? '0');
                    return ImportScreen(projectId: projectId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/computation',
              builder: (context, state) => const ComputationHubScreen(),
              routes: [
                GoRoute(
                  path: 'traverse',
                  builder: (context, state) => const TraverseScreen(),
                ),
                GoRoute(
                  path: 'cogo_inverse',
                  builder: (context, state) => const CogoScreen(isForward: false),
                ),
                 GoRoute(
                  path: 'cogo_forward',
                  builder: (context, state) => const CogoScreen(isForward: true),
                ),

                 GoRoute(
                  path: 'trig_leveling',
                  builder: (context, state) => const LevelingScreen(),
                ),
                GoRoute(
                  path: 'differential_leveling',
                  builder: (context, state) => const LevelingDashboardScreen(),
                  routes: [
                    GoRoute(
                      path: 'book/:loopId',
                      builder: (context, state) {
                         final loopId = int.parse(state.pathParameters['loopId']!);
                         return LevelingBookScreen(loopId: loopId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'device_connection',
                  builder: (context, state) => const DeviceConnectionScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class SurveyorProApp extends StatelessWidget {
  const SurveyorProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Surveyor Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // We only have dark theme based on requirements
      routerConfig: _router,
    );
  }
}
