## 0.1.0

- Initial release
- iOS + Android support via `flutter_appauth`
- `TalerIdClient.create()` async factory + `login`/`logout`/`getUser`/`getAccessToken`/`isAuthenticated`/`authState`
- Pluggable storage (`SecureStorage` default, `MemoryStorage` for tests)
- On-demand token refresh with concurrent-call guard
- `TalerIdAuthError` with `TalerIdErrorCode` enum
