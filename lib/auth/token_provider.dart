import 'dart:async';
import 'dart:convert';

import 'package:firedart/auth/client.dart';
import 'package:firedart/auth/token_store.dart';
import 'package:rxdart/rxdart.dart';

import 'exceptions.dart';

const _tokenExpirationThreshold = Duration(seconds: 30);

class TokenProvider {
  final KeyClient client;
  final TokenStore _tokenStore;

  late BehaviorSubject<bool> _signInStateSubject;

  TokenProvider(this.client, this._tokenStore) {
    _signInStateSubject = BehaviorSubject<bool>.seeded(_tokenStore.hasToken);
  }

  String? get userId => _tokenStore.userId;

  String? get refreshToken => _tokenStore.refreshToken;

  bool get isSignedIn => _tokenStore.hasToken;

  ValueStream<bool> get signInState => _signInStateSubject.stream;

  Future<String> get idToken async {
    if (!isSignedIn) throw SignedOutException();

    if (_tokenStore.expiry
        .subtract(_tokenExpirationThreshold)
        .isBefore(DateTime.now().toUtc())) {
      await _refresh();
    }
    return _tokenStore.idToken;
  }

  Future<void> setToken(Map<String, dynamic> map) async {
    if (map['localId'] is! String ||
        map['idToken'] is! String ||
        map['refreshToken'] is! String ||
        map['expiresIn'] is! String) {
      throw Exception('Wrong token format');
    }

    await _tokenStore.setToken(
      map['localId'],
      map['idToken'],
      map['refreshToken'],
      int.parse(map['expiresIn']),
    );

    _notifyState();
  }

  void signOut() {
    _tokenStore.clear();
    _notifyState();
  }

  Future _refresh() async {
    var response = await client.post(
      Uri.parse('https://securetoken.googleapis.com/v1/token'),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _tokenStore.refreshToken,
      },
    );

    switch (response.statusCode) {
      case 200:
        var map = json.decode(response.body);
        await _tokenStore.setToken(
          map['localId'],
          map['id_token'],
          map['refresh_token'],
          int.parse(map['expires_in']),
        );
        break;
      case 400:
        signOut();
        throw AuthException(response.body);
    }
  }

  void _notifyState() => _signInStateSubject.add(isSignedIn);
}
