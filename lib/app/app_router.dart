import 'package:go_router/go_router.dart';

import '../core/models/app_models.dart';
import '../features/admin/presentation/admin_screens.dart';
import '../features/applications/presentation/application_screens.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/messages/presentation/message_screens.dart';
import '../features/notifications/presentation/notification_screens.dart';
import '../features/profile/presentation/profile_screens.dart';
import '../features/properties/presentation/property_screens.dart';
import '../features/shells/admin_shell.dart';
import '../features/shells/user_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) => OtpVerificationScreen(
        payload: state.extra is OtpRoutePayload
            ? state.extra! as OtpRoutePayload
            : null,
      ),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordScreen(
        payload: state.extra is ResetPasswordPayload
            ? state.extra! as ResetPasswordPayload
            : null,
      ),
    ),
    GoRoute(path: '/user', builder: (context, state) => const UserShell()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminShell()),
    GoRoute(
      path: '/user/application/:id',
      builder: (context, state) => UserApplicationDetailScreen(
        applicationId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/property/:id',
      builder: (context, state) =>
          PropertyDetailScreen(propertyId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/apply/:propertyId',
      builder: (context, state) => ApplicationFormScreen(
        propertyId: state.pathParameters['propertyId']!,
      ),
    ),
    GoRoute(
      path: '/chat/:participantId',
      builder: (context, state) => ChatThreadScreen(
        participantId: state.pathParameters['participantId']!,
        participantName:
            (state.extra as Map<String, dynamic>?)?['participantName']
                as String?,
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/complaints',
      builder: (context, state) => const ComplaintsScreen(),
    ),
    GoRoute(
      path: '/agreements',
      builder: (context, state) => const AgreementsScreen(),
    ),
    GoRoute(
      path: '/admin/property-form',
      builder: (context, state) =>
          AdminPropertyFormScreen(property: state.extra as PropertyItem?),
    ),
    GoRoute(
      path: '/admin/application/:id',
      builder: (context, state) => AdminApplicationReviewScreen(
        applicationId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/admin/payments',
      builder: (context, state) => const AdminPaymentsScreen(),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      path: '/admin/complaints',
      builder: (context, state) => const AdminComplaintsScreen(),
    ),
    GoRoute(
      path: '/admin/announcements',
      builder: (context, state) => const AdminAnnouncementsScreen(),
    ),
  ],
);
