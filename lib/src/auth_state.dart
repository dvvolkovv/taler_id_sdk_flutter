import 'dart:convert';
import 'package:equatable/equatable.dart';

/// User info from `/oauth/me`, with arbitrary OIDC claims.
class UserInfo extends Equatable {
  /// Subject identifier — the OIDC `sub` claim. Stable per user.
  final String sub;

  /// All OIDC claims returned by `/oauth/me` (email, name, picture, etc.).
  final Map<String, Object?> claims;

  /// Constructs a UserInfo with a subject and a claim map.
  const UserInfo({required this.sub, required this.claims});

  /// Convenience accessor for the standard `email` claim.
  String? get email => claims['email'] as String?;

  /// Convenience accessor for the standard `name` claim.
  String? get name => claims['name'] as String?;

  /// Returns the named claim cast to [T], or `null` if absent.
  T? claim<T>(String key) => claims[key] as T?;

  /// Serializes this UserInfo to a JSON-compatible map.
  Map<String, Object?> toJson() => {'sub': sub, ...claims};

  /// Parses a UserInfo from a JSON-compatible map.
  factory UserInfo.fromJson(Map<String, Object?> json) {
    final claims = Map<String, Object?>.from(json);
    final sub = claims.remove('sub') as String;
    return UserInfo(sub: sub, claims: claims);
  }

  /// Serializes to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Parses from a JSON string.
  factory UserInfo.fromJsonString(String s) =>
      UserInfo.fromJson(jsonDecode(s) as Map<String, Object?>);

  @override
  List<Object?> get props => [sub, claims];
}

/// Reactive auth state exposed by `TalerIdClient.authState`.
class AuthState extends Equatable {
  /// The authenticated user, or `null` when unauthenticated.
  final UserInfo? user;

  /// True when access token + non-expired expiry are present in storage.
  final bool isAuthenticated;

  /// True during async operations like `login()` or initial hydration.
  final bool isLoading;

  /// Constructs an immutable [AuthState].
  const AuthState({
    this.user,
    required this.isAuthenticated,
    required this.isLoading,
  });

  /// The default unauthenticated, idle state.
  static const AuthState initial = AuthState(
    user: null,
    isAuthenticated: false,
    isLoading: false,
  );

  /// Returns a copy of this state with the given fields replaced.
  /// Pass [clearUser] = true to set [user] to null regardless of the [user] argument.
  AuthState copyWith({
    UserInfo? user,
    bool? isAuthenticated,
    bool? isLoading,
    bool clearUser = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [user, isAuthenticated, isLoading];
}
