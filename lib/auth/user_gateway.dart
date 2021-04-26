import 'dart:async';
import 'dart:convert';

import 'package:firedart/auth/client.dart';
import 'package:firedart/auth/token_provider.dart';

class UserGateway {
  final UserClient _client;

  UserGateway(KeyClient client, TokenProvider tokenProvider)
      : _client = UserClient(client, tokenProvider);

  Future<void> requestEmailVerification() =>
      _post('sendOobCode', {'requestType': 'VERIFY_EMAIL'});

  Future<User> getUser() async {
    var map = await (_post('lookup', {}) as FutureOr<Map<String, dynamic>>);
    return User.fromMap(map['users'][0]);
  }

  Future<void> changePassword(String password) async {
    await _post('update', {
      'password': password,
    });
  }

  Future<void> updateProfile(String? displayName, String? photoUrl) async {
    await _post('update', {
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
  }

  Future<void> deleteAccount() async {
    await _post('delete', {});
  }

  Future<Map<String, dynamic>?> _post<T>(
      String method, Map<String, String> body) async {
    var requestUrl =
        'https://identitytoolkit.googleapis.com/v1/accounts:$method';

    var response = await _client.post(
      Uri.parse(requestUrl),
      body: body,
    );

    return json.decode(response.body);
  }
}

class User {
  final String id;
  final String displayName;
  final String photoUrl;
  final String email;
  final bool emailVerified;

  User._({
    required this.id,
    required this.displayName,
    required this.photoUrl,
    required this.email,
    required this.emailVerified,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    if (map['localId'] is! String ||
        map['displayName'] is! String ||
        map['photoUrl'] is! String ||
        map['email'] is! String ||
        map['emailVerified'] is! bool) {
      throw Exception('Wrong user data format');
    }

    return User._(
      id: map['localId'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      email: map['email'],
      emailVerified: map['emailVerified'],
    );
  }

  Map<String, dynamic> toMap() => {
        'localId': id,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'email': email,
        'emailVerified': emailVerified,
      };

  @override
  String toString() => toMap().toString();
}
