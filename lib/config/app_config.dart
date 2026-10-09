/// Build-time configuration, set with `--dart-define`.
///
/// DISCOUNT_API_URL points to the public API of the discount-scraper backend
/// (`/api/public/v1`). The default `/api/discounts` is a relative path that
/// the Baskit nginx container proxies to the discount-scraper API, so the web
/// build works without CORS. Mobile builds and `flutter run -d chrome` need an
/// absolute URL, e.g.
/// `--dart-define=DISCOUNT_API_URL=http://localhost:3001/api/public/v1`.
class AppConfig {
  static const String discountApiUrl = String.fromEnvironment(
    'DISCOUNT_API_URL',
    defaultValue: '/api/discounts',
  );

  /// The discount API base URL resolved to an absolute URI.
  /// Relative values are resolved against the page URL (web only).
  static Uri get discountApiBaseUri {
    final uri = Uri.parse(discountApiUrl);
    return uri.hasScheme ? uri : Uri.base.resolveUri(uri);
  }
}
