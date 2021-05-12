import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:firedart/storage/metadata.dart';
import 'package:firedart/auth/firebase_auth.dart';
import 'package:firedart/storage/storage_platform.dart';
import 'package:http/http.dart';

class FirebaseStorageException implements Exception {
  final String url;
  final String message;
  final String? resultContent;
  const FirebaseStorageException(
      {required this.url, required this.message, this.resultContent});

  @override
  String toString() {
    return 'Firebase URL: $url $message';
  }
}

class DownloadProgress {
  double? get progress => size != null ? downloaded / size! : null;
  final List<List<int>> chunks;
  final int downloaded;
  final int? size;
  const DownloadProgress({
    required this.chunks,
    required this.downloaded,
    required this.size,
  });

  Uint8List get data {
    final recievedSize =
        chunks.fold<int>(0, (value, element) => value + element.length);
    final bytes = Uint8List(recievedSize);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return bytes;
  }
}

class StorageBucketListItem {
  FirebaseStorage storage;
  String name;
  String bucket;

  StorageBucketListItem({
    required this.name,
    required this.bucket,
    required this.storage,
  });

  factory StorageBucketListItem.fromMap(
      FirebaseStorage storage, Map<String, dynamic> map) {
    if (map['name'] is! String || map['bucket']! is String) {
      throw Exception('Name and bucket ust be provided!');
    }
    return StorageBucketListItem(
        name: map['name'], bucket: map['bucket'], storage: storage);
  }

  String getFilename() {
    if (name.isEmpty) return '';
    var i = name.lastIndexOf('/');
    return name.substring(i + 1);
  }

  String getDirectory() {
    if (name.isEmpty) return '';
    var i = name.lastIndexOf('/');
    return i == -1 ? name : name.substring(0, i);
  }

  FirebaseStorageReference getReference() =>
      FirebaseStorageReference(storage, name);

  @override
  String toString() => name;
}

class StorageBucketList {
  List<StorageBucketListItem> items = [];
  List<String>? prefixes = [];
  String? nextPageToken;
  StorageBucketList.fromMap({
    required FirebaseStorage storage,
    required Map<String, dynamic> map,
  }) {
    if (map['items'] is! List) {
      throw ArgumentError('Map must contain bucket items!');
    }

    prefixes = map['prefixes']?.cast<String>();
    nextPageToken = map['nextPagetoken'];
    for (var item in map['items']) {
      items.add(StorageBucketListItem.fromMap(storage, item));
    }
  }
}

class FirebaseStorage {
  final String storageBucket;
  final FirebaseAuth auth = FirebaseAuth.instance;

  FirebaseStorage.instanceFor(this.storageBucket);

  FirebaseStorageReference ref([String? path]) {
    return FirebaseStorageReference(this, path ?? '/');
  }
}

class FirebaseStorageReference {
  static final String _firebaseStorageEndpoint =
      'https://firebasestorage.googleapis.com/v0/b/';

  final FirebaseStorage storage;
  late Pointer _pointer;

  FirebaseStorageReference(this.storage, String? childRoot) {
    _pointer = Pointer(childRoot);
  }

  FirebaseStorageReference child(String path) {
    return FirebaseStorageReference(
      storage,
      _pointer.child(path),
    );
  }

  Future<dynamic> listAll() async {
    return await _internalRequest(_getListUrl());
  }

  Stream<double> _putRequest(Request request) async* {
    final response = await storage.auth.httpClient.send(request);
    if (response.statusCode != 200) {
      throw Exception('Server responded with error ${response.statusCode}: '
          '${response.reasonPhrase}');
    }

    var uploaded = 0.0;
    yield uploaded;
    await for (final chunk in response.stream) {
      uploaded += chunk.length;
      yield uploaded / response.contentLength!;
    }
  }

  Stream<double> putBytes(Uint8List data) async* {
    final requestUrl = _getTargetUrl();
    final token = await storage.auth.tokenProvider.idToken;
    final request = Request('POST', Uri.parse(requestUrl));
    request.headers[HttpHeaders.authorizationHeader] = 'Firebase $token';
    request.headers[HttpHeaders.contentTypeHeader] = 'application/octet-stream';
    request.bodyBytes = data;

    yield* _putRequest(request);
  }

  Stream<double> putFile(File file) async* {
    yield* putBytes(await file.readAsBytes());
  }

  Stream<double> putString(String data) async* {
    final requestUrl = _getTargetUrl();
    final token = await storage.auth.tokenProvider.idToken;
    final request = Request('POST', Uri.parse(requestUrl));
    request.headers[HttpHeaders.authorizationHeader] = 'Firebase $token';
    request.headers[HttpHeaders.contentTypeHeader] = 'text/plain';
    request.body = data;

    yield* _putRequest(request);
  }

  Stream<DownloadProgress> getBytes() async* {
    final requestUrl = await getDownloadUrl();

    try {
      yield* _getBytes(requestUrl);
    } on Exception catch (error) {
      throw FirebaseStorageException(
          url: requestUrl, message: error.toString());
    }
  }

  Stream<DownloadProgress> _getBytes(String requestUrl) async* {
    final http = storage.auth.httpClient;
    final token = await storage.auth.tokenProvider.idToken;
    final request = Request('GET', Uri.parse(requestUrl));
    request.headers[HttpHeaders.authorizationHeader] = 'Firebase $token';

    final response = await http.send(request);
    if (response.statusCode != 200) {
      throw Exception('Server responded with error ${response.statusCode}: '
          '${response.reasonPhrase}');
    }

    final totalSize = response.contentLength;
    final chunks = <List<int>>[];
    var downloaded = 0;

    yield DownloadProgress(
      size: totalSize,
      downloaded: downloaded,
      chunks: chunks,
    );

    await for (final chunk in response.stream) {
      chunks.add(chunk);
      downloaded += chunk.length;
      yield DownloadProgress(
        size: totalSize,
        downloaded: downloaded,
        chunks: chunks,
      );
    }

    final recievedSize =
        chunks.fold<int>(0, (value, element) => value + element.length);

    yield DownloadProgress(
      size: recievedSize,
      downloaded: downloaded,
      chunks: chunks,
    );
  }

  Stream<double> getFile(File file) async* {
    final requestUrl = await getDownloadUrl();
    try {
      DownloadProgress? state;
      await for (final sstate in _getBytes(requestUrl)) {
        state = sstate;
        final progress = state.progress;
        if (progress != null) {
          yield progress;
        }
      }
      if (state == null) {
        throw Exception('No data recieved');
      }
      await file.writeAsBytes(state.data);
      yield 1;
    } on Exception catch (error) {
      throw FirebaseStorageException(
          url: requestUrl, message: error.toString());
    }
  }

  Future<String> getDownloadUrl() async {
    var data = await _performFetch();
    if (data['downloadTokens'] == null) {
      throw Exception(
          'Could not extract "downloadTokens" property from response. '
          'Response: $data');
    }

    return _getFullDownloadUrl() + data['downloadTokens'];
  }

  Future<FullMetadata> getMetaData() async {
    var data = await _performFetch();
    return FullMetadata(data);
  }

  Future<void> delete() async {
    final requestUrl = _getDownloadUrl();
    var resultContent = 'N/A';
    try {
      final http = storage.auth.httpClient;
      final token = await storage.auth.tokenProvider.idToken;
      final result = await http.delete(Uri.parse(requestUrl),
          headers: {'Authorization': 'Firebase $token'});
      resultContent = result.body;

      if (result.statusCode != 200) {
        throw Exception(
            'Server responded with error ${result.statusCode}: ${result.body}');
      }
    } on Exception catch (error) {
      throw FirebaseStorageException(
          url: requestUrl,
          message: error.toString(),
          resultContent: resultContent);
    }
  }

  String _getTargetUrl() {
    return '$_firebaseStorageEndpoint${storage.storageBucket}/o?name=${_getEscapedPath()}';
  }

  String _getDownloadUrl() {
    return '$_firebaseStorageEndpoint${storage.storageBucket}/o/${_getEscapedPath()}';
  }

  String _getFullDownloadUrl() {
    return _getDownloadUrl() + '?alt=media&token=';
  }

  String _getEscapedPath() {
    return Uri.encodeComponent(_pointer.path);
  }

  String _getListUrl({
    int maxResults = 1000,
    String? pageToken,
  }) {
    if (maxResults > 1000 || maxResults < 1) {
      throw Exception(
          'maxResults must be a positive value between 1 and 1000 inclusive.');
    }

    String reqUrl;
    reqUrl = '$_firebaseStorageEndpoint${storage.storageBucket}/o/?';
    reqUrl +=
        'prefix=${_pointer.isRoot ? '' : _pointer.path + Uri.encodeComponent("/")}';

    if (pageToken != null && pageToken.isNotEmpty) {
      reqUrl += '&pageToken=$pageToken';
    }

    reqUrl += '&maxResults=$maxResults';
    reqUrl += '&delimiter=${Uri.encodeComponent("/")}';

    return reqUrl;
  }

  Future<Map<String, dynamic>> _performFetch() async {
    final requestUrl = _getDownloadUrl();
    try {
      final http = storage.auth.httpClient;
      final token = await storage.auth.tokenProvider.idToken;
      final result = await http.read(Uri.parse(requestUrl),
          headers: {'Authorization': 'Firebase $token'});

      return jsonDecode(result);
    } on Exception catch (error) {
      throw FirebaseStorageException(
          url: requestUrl, message: error.toString());
    }
  }

  Future<StorageBucketList> _internalRequest(String fullUrl) async {
    try {
      final http = storage.auth.httpClient;
      final token = await storage.auth.tokenProvider.idToken;
      final result = await http.get(Uri.parse(fullUrl),
          headers: {'Authorization': 'Firebase $token'});

      if (result.statusCode != 200) {
        throw Exception(
            'Server responded with error ${result.statusCode}: ${result.body}');
      }
      final bucket = StorageBucketList.fromMap(
        storage: storage,
        map: jsonDecode(result.body),
      );
      return bucket;
    } on Exception catch (error) {
      throw FirebaseStorageException(url: fullUrl, message: error.toString());
    }
  }
}
