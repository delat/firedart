abstract class TokenStore {
  Token? _token;

  String get userId =>
      _token != null ? _token!._userId : throw Exception('No token available!');

  String get idToken => _token != null
      ? _token!._idToken
      : throw Exception('No token available!');

  String get refreshToken => _token != null
      ? _token!._refreshToken
      : throw Exception('No token available!');

  DateTime get expiry =>
      _token != null ? _token!._expiry : throw Exception('No token available!');

  bool get hasToken => _token != null;

  Future<void> setToken(
    String userId,
    String idToken,
    String refreshToken,
    int expiresIn,
  ) async {
    _token = Token(
      userId,
      idToken,
      refreshToken,
      DateTime.now().add(Duration(seconds: expiresIn)),
    );
    await write(_token!);
  }

  Future<void> initialize() async {
    _token = await read();
  }

  /// Force refresh - useful for testing
  Future<void> expireToken() async {
    _token = Token(
      _token?._userId ?? '',
      _token?._idToken ?? '',
      _token?._refreshToken ?? '',
      DateTime.now(),
    );
    await write(_token!);
  }

  void clear() {
    delete();
    _token = null;
  }

  /// Restore the refresh token from storage, returns null if token isn't stored
  Future<Token?> read();

  /// Persist the refresh token
  Future<void> write(Token token);

  Future<void> delete();
}

/// Doesn't actually persist tokens. Useful for testing or in environments where
/// persistence isn't available but it's fine signing in for each session.
class VolatileStore extends TokenStore {
  @override
  Future<Token?> read() => Future.value(null);

  @override
  Future<void> write(Token token) {
    return Future.value();
  }

  @override
  Future<void> delete() {
    return Future.value();
  }
}

class Token {
  final String _userId;
  final String _idToken;
  final String _refreshToken;
  final DateTime _expiry;

  Token(this._userId, this._idToken, this._refreshToken, this._expiry);

  Token.fromMap(Map<String, dynamic> map)
      : this(
          map['userId'] ?? '',
          map['idToken'] ?? '',
          map['refreshToken'] ?? '',
          DateTime.parse(map['expiry']),
        );

  Map<String, dynamic> toMap() => {
        'userId': _userId,
        'idToken': _idToken,
        'refreshToken': _refreshToken,
        'expiry': _expiry.toIso8601String(),
      };
}
