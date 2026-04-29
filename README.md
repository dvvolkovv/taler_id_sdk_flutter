# talerid_oauth

Flutter SDK for **Sign in with Taler ID**. iOS + Android via `flutter_appauth`. Authorization Code + PKCE in ~5 lines.

## Install

```bash
flutter pub add talerid_oauth
```

## Quickstart

```dart
import 'package:talerid_oauth/talerid_oauth.dart';

final client = await TalerIdClient.create(
  clientId: 'your-client-id',
  redirectUri: 'com.yourapp://oauth/callback',
);

await client.login();          // opens in-app browser, returns when authenticated
final user = await client.getUser();
final token = await client.getAccessToken();
await client.logout();
```

Use `client.authState` (`ValueListenable<AuthState>`) inside `ValueListenableBuilder` to react to login/logout.

## Platform setup

### iOS — `ios/Runner/Info.plist`

Add a URL type matching your `redirectUri` scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>com.yourapp</string></array>
  </dict>
</array>
```

### Android — `android/app/src/main/AndroidManifest.xml`

Add an intent-filter to the main activity:

```xml
<intent-filter android:autoVerify="false">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.yourapp" />
</intent-filter>
```

## Configuration

| Option        | Default                              | Description                                            |
| ------------- | ------------------------------------ | ------------------------------------------------------ |
| `clientId`    | (required)                           | OAuth client_id from your Taler ID registration        |
| `redirectUri` | (required)                           | Custom URL scheme registered in your iOS/Android app   |
| `scope`       | `'openid profile email'`             | Space-separated scopes                                 |
| `storage`     | `SecureStorage()`                    | Pluggable; `MemoryStorage` for tests, custom for Hive  |
| `issuer`      | `'https://id.taler.tirol/oauth'`     | Override for staging                                   |
| `onLog`       | `(_, __, [___]) => {}`               | Diagnostic callback `(level, message, [meta])`         |

## API

| Member                                  | Description                                              |
| --------------------------------------- | -------------------------------------------------------- |
| `await TalerIdClient.create(...)`       | Async factory; hydrates state from storage               |
| `await client.login()`                  | Opens browser, waits, stores tokens                      |
| `await client.logout({endSession?})`    | Clears storage; with `endSession:true` opens RP logout    |
| `await client.getUser()`                | Fetch and cache `/oauth/me` userinfo                     |
| `await client.getAccessToken()`         | Returns access_token, auto-refreshes if near expiry      |
| `client.isAuthenticated`                | Sync, no I/O                                             |
| `client.authState`                      | `ValueListenable<AuthState>` for reactive UI             |

## Errors

```dart
import 'package:talerid_oauth/talerid_oauth.dart';

try {
  await client.login();
} on TalerIdAuthError catch (err) {
  if (err.code == TalerIdErrorCode.userCancelled) { /* user dismissed browser */ }
}
```

Codes: `loginRequired` · `consentRequired` · `network` · `config` · `userCancelled` · `invalidGrant`.

## See also

- Live integration guide: <https://id.taler.tirol/oauth-guide.html>
- Brand assets and buttons: <https://id.taler.tirol/brand>
- JavaScript SDK: [`@taler-id/oauth-client`](https://www.npmjs.com/package/@taler-id/oauth-client) (browser SPAs)
- Source: <https://github.com/dvvolkovv/taler_id_sdk_flutter>

## License

MIT
