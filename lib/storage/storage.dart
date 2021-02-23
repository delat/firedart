import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:firedart/storage/metadata.dart';
import 'package:firedart/auth/firebase_auth.dart';
import 'package:firedart/storage/storage_platform.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class StorageBucketListItem {
  FirebaseStorage storage;
  String name;
  String bucket;

  StorageBucketListItem({this.name, this.bucket, this.storage});

  factory StorageBucketListItem.fromMap(
          FirebaseStorage storage, Map<String, dynamic> map) =>
      StorageBucketListItem(
          name: map['name'], bucket: map['bucket'], storage: storage);

  String getFilename() {
    if ((name == null || name.isEmpty)) return '';
    var i = name.lastIndexOf('/');
    return name.substring(i + 1);
  }

  String getDirectory() {
    if (name == null || name.isEmpty) return '';
    var i = name.lastIndexOf('/');
    return i == -1 ? name : name.substring(0, i);
  }

  FirebaseStorageReference getReference() =>
      FirebaseStorageReference(storage, name);

  @override
  String toString() => name;
}

class StorageBucketList {
  StorageBucketList.fromMap(Map<String, dynamic> _map);
  List<StorageBucketListItem> items;
  List<String> prefixes;
  String nextPageToken;
}

class FirebaseStorage {
  final String storageBucket;
  final FirebaseAuth auth = FirebaseAuth.instance;

  FirebaseStorage.instanceFor(this.storageBucket);

  FirebaseStorageReference ref([String path]) {
    return FirebaseStorageReference(this, path ?? '/');
  }
}

class FirebaseStorageReference {
  static final String _firebaseStorageEndpoint =
      'https://firebasestorage.googleapis.com/v0/b/';

  final FirebaseStorage storage;
  Pointer _pointer;

  FirebaseStorageReference(this.storage, String childRoot) {
    _pointer = Pointer(childRoot);
  }

  FirebaseStorageReference child(String path) {
    return FirebaseStorageReference(
      storage,
      _pointer.child(path),
    );
  }

  Future<dynamic> listAll() async {
    return await _internalRequest(_getListUrl(forPrefix: false));
  }

  Future<void> putData(Uint8List data, {SettableMetadata metadata}) async {
    var requestUrl = _getTargetUrl();
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var headers = {
        'Authorization': 'Firebase $token',
        'Content-Type': 'application/octet-stream',
      };
      if (metadata != null) {
        headers.addAll(metadata.asMap());
      }
      var result =
          await http.post(Uri.parse(requestUrl), headers: headers, body: data);

      if (result.statusCode != 200) {
        throw Exception('Server responded with error: ${result.statusCode}');
      }
    } catch (ex) {
      throw Exception([requestUrl, ex]);
    }
  }

  Future<void> putFile(File file, {SettableMetadata metadata}) async {
    var requestUrl = _getTargetUrl();
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var data = await file.readAsBytes();
      var headers = {
        'Authorization': 'Firebase $token',
        'Content-Type':
            lookupMimeType(p.basename(file.path)) ?? 'application/octet-stream',
      };
      if (metadata != null) {
        headers.addAll(metadata.asMap());
      }
      var result =
          await http.post(Uri.parse(requestUrl), headers: headers, body: data);

      if (result.statusCode != 200) {
        throw Exception('Server responded with error: ${result.statusCode}');
      }
    } catch (ex) {
      throw Exception([requestUrl, ex]);
    }
  }

  Future<void> putString(String data, {SettableMetadata metadata}) async {
    var requestUrl = _getTargetUrl();
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var headers = {
        'Authorization': 'Firebase $token',
        'Content-Type': 'text/plain',
      };
      if (metadata != null) {
        headers.addAll(metadata.asMap());
      }
      var result =
          await http.post(Uri.parse(requestUrl), headers: headers, body: data);

      if (result.statusCode != 200) {
        throw Exception('Server responded with error: ${result.statusCode}');
      }
    } catch (ex) {
      throw Exception([requestUrl, ex]);
    }
  }

  Future<void> writeToFile(File file) async {
    var requestUrl = await getDownloadUrl();
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var data = await http.readBytes(Uri.parse(requestUrl),
          headers: {'Authorization': 'Firebase $token'});

      if (file.existsSync() == false) {
        await file.create();
      }

      await file.writeAsBytes(data);
    } catch (ex) {
      throw Exception([requestUrl, ex]);
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

  Future<FullMetadata> getMetaData() async {
    var data = await _performFetch();
    return FullMetadata(data);
  }

  Future<void> delete() async {
    var requestUrl = _getDownloadUrl();
    var resultContent = 'N/A';
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var result = await http.delete(Uri.parse(requestUrl),
          headers: {'Authorization': 'Firebase $token'});
      resultContent = result.body;

      if (result.statusCode != 200) {
        throw Exception('Server responded with error: ${result.statusCode}');
      }
    } catch (ex) {
      throw Exception([requestUrl, resultContent, ex]);
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
    return Uri.encodeComponent(_pointer.path);
  }

  String _getListUrl({
    FirebaseStorageReference child,
    bool forPrefix,
    int maxResults = 1000,
    String pageToken,
  }) {
    if (maxResults > 1000 || maxResults < 1) {
      throw Exception(
          'maxResults must be a positive value between 1 and 1000 inclusive.');
    }

    String reqUrl;
    var first = true;

    reqUrl = '${_firebaseStorageEndpoint}${storage.storageBucket}/o/?';

    if (child != null) {
      reqUrl += 'prefix=${child._getEscapedPath()}${Uri.encodeComponent("/")}';
      first = false;
    }

    if (pageToken != null && pageToken.isNotEmpty) {
      if (!first) {
        reqUrl += '&';
      } else {
        first = false;
      }
      reqUrl += 'pageToken=$pageToken';
    }

    if (!first) {
      reqUrl += '&';
    }
    reqUrl += 'maxResults=$maxResults';

    if (forPrefix) {
      reqUrl += '&delimiter=/';
    }

    return reqUrl;
  }

  Future<Map<String, dynamic>> _performFetch() async {
    var requestUrl = _getDownloadUrl();
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var result = await http.read(Uri.parse(requestUrl),
          headers: {'Authorization': 'Firebase $token'});

      return jsonDecode(result);
    } catch (ex) {
      throw Exception([requestUrl, ex]);
    }
  }

  Future<dynamic> _internalRequest(String fullUrl) async {
    try {
      var http = storage.auth.httpClient;
      var token = await storage.auth.tokenProvider.idToken;
      var result = await http.get(Uri.parse(fullUrl),
          headers: {'Authorization': 'Firebase $token'});

      if (result.statusCode != 200) {
        throw Exception('Server responded with error: ${result.statusCode}');
      }
      var bucket = jsonDecode(result.body);
      return bucket;
    } catch (ex) {
      throw Exception([fullUrl, ex]);
    }
  }
}
