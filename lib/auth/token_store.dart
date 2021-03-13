abstract class TokenStore {
  Token? _token;

  String? get userId => _token!._userId;

  String? get idToken => _token!._idToken;

  String? get refreshToken => _token!._refreshToken;

  DateTime get expiry => _token!._expiry;

  bool get hasToken => _token != null;

  Future<void> setToken(
    String? userId,
    String? idToken,
    String? refreshToken,
    int expiresIn,
  ) async {
    assert(idToken != null && refreshToken != null && expiresIn != null);
    var expiry = DateTime.now().add(Duration(seconds: expiresIn));
    _token = Token(userId, idToken, refreshToken, expiry);
    await write(_token);
  }

  Future<void> initialize() async {
    _token = await read();
  }

  /// Force refresh - useful for testing
  Future<void> expireToken() async {
    _token = Token(
      _token!._userId,
      _token!._idToken,
      _token!._refreshToken,
      DateTime.now(),
    );
    await write(_token);
  }

  void clear() {
    _token = null;
    delete();
  }

  /// Restore the refresh token from storage, returns null if token isn't stored
  Future<Token> read();

  /// Persist the refresh token
  Future<void> write(Token? token);

  Future<void> delete();
}

/// Doesn't actually persist tokens. Useful for testing or in environments where
/// persistence isn't available but it's fine signing in for each session.
class VolatileStore extends TokenStore {
  @override
  Future<Token> read() => Future.value(null);

  @override
  Future<void> write(Token? token) {
    return Future.value();
  }

  @override
  Future<void> delete() {
    return Future.value();
  }
}

class Token {
  final String? _userId;
  final String? _idToken;
  final String? _refreshToken;
  final DateTime _expiry;

  Token(this._userId, this._idToken, this._refreshToken, this._expiry);

  Token.fromMap(Map<String, dynamic> map)
      : this(
          map['userId'],
          map['idToken'],
          map['refreshToken'],
          DateTime.parse(map['expiry']),
        );

  Map<String, dynamic> toMap() => {
        'userId': _userId,
        'idToken': _idToken,
        'refreshToken': _refreshToken,
        'expiry': _expiry.toIso8601String(),
      };
}
