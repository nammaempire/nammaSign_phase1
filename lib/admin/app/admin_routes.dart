/// All admin portal route paths in one place.
class AdminRoutes {
  AdminRoutes._();

  static const String login = '/login';
  static const String notAuthorized = '/not-authorized';

  static const String dashboard = '/';
  static const String bookings = '/bookings';
  static const String bookingDetail = '/bookings/:id';
  static const String users = '/users';
  static const String userDetail = '/users/:id';
  static const String areas = '/areas';
  static const String finance = '/finance';
  static const String faqs = '/faqs';

  static String bookingDetailFor(String id) => '/bookings/$id';
  static String userDetailFor(String id) => '/users/$id';
}

/// Top-level section the shell highlights in the sidebar.
enum AdminSection { dashboard, bookings, users, areas, finance, faqs }
