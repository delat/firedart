import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firedart/storage/firebase_metadata.dart';
import 'package:firedart/auth/firebase_auth.dart';

class FirebaseStorage {
  final String storageBucket;
  FirebaseAuth auth;

  FirebaseStorage(this.storageBucket) {
    try {
      auth = FirebaseAuth.instance;
    } catch (e) {
      throw Exception('Firebase is not initialized');
    }
  }

  FirebaseStorageReference child(String childRoot) {
    return FirebaseStorageReference(this, childRoot);
  }
}

class FirebaseStorageReference {
  static final String _firebaseStorageEndpoint =
      'https://firebasestorage.googleapis.com/v0/b/';

  final FirebaseStorage storage;
  List<String> children;

  FirebaseStorageReference(this.storage, String childRoot) {
    children = [];
    children.add(childRoot);
  }

  FirebaseStorageReference child(String name) {
    children.add(name);
    return this;
  }

  Future<void> upload(Uint8List data,
      {void Function(int value) onProgress}) async {
    var url = _getTargetUrl();
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var result = await http.post(url,
          headers: {'Authorization': 'Firebase $token'}, body: data);

      if (result.statusCode != 200) {
        throw Exception('Server responded with error: ${result.statusCode}');
      }
    } catch (ex) {
      throw Exception([url, ex]);
    }
  }

  Future<Uint8List> download() async {
    var downloadUrl = await getDownloadUrl();
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var file = await http.readBytes(downloadUrl,
          headers: {'Authorization': 'Firebase $token'});
      return file;
    } catch (ex) {
      throw Exception([downloadUrl, ex]);
    }
  }

  Future<String> getDownloadUrl() async {
    var data = await _performFetch();
    if (data['downloadTokens'] == null) {
      throw Exception(
          'Could not extract "downloadTokens" property from response. Response: $data');
    }

    return _getFullDownloadUrl() + data['downloadTokens'];
  }

  Future<FirebaseMetaData> getMetaData() async {
    var data = await _performFetch();
    return FirebaseMetaData.fromMap(data);
  }

  Future<void> delete() async {
    var url = _getDownloadUrl();
    var resultContent = 'N/A';
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var result =
          await http.delete(url, headers: {'Authorization': 'Firebase $token'});
      resultContent = result.body;

      if (result.statusCode != 200) {
        throw Exception('Server responded with error: ${result.statusCode}');
      }
    } catch (ex) {
      throw Exception([url, resultContent, ex]);
    }
  }

  String _getTargetUrl() {
    return '${_firebaseStorageEndpoint}${storage.storageBucket}/o?name=${_getEscapedPath()}';
  }

  String _getDownloadUrl() {
    return '${_firebaseStorageEndpoint}${storage.storageBucket}/o/${_getEscapedPath()}';
  }

  String _getFullDownloadUrl() {
    return _getDownloadUrl() + '?alt=media&token=';
  }

  String _getEscapedPath() {
    return Uri.encodeComponent(children.join('/'));
  }

  Future<Map<String, dynamic>> _performFetch() async {
    var url = _getDownloadUrl();
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var result =
          await http.read(url, headers: {'Authorization': 'Firebase $token'});

      return jsonDecode(result);
    } catch (ex) {
      throw Exception([url, ex]);
    }
  }
}
