import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:firedart/storage/metadata.dart';
import 'package:firedart/auth/firebase_auth.dart';
import 'package:firedart/storage/storage_platform.dart';
import 'package:http/http.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class StorageBucketListItem {
  FirebaseStorage? storage;
  String? name;
  String? bucket;

  StorageBucketListItem({this.name, this.bucket, this.storage});

  factory StorageBucketListItem.fromMap(
          FirebaseStorage? storage, Map<String, dynamic> map) =>
      StorageBucketListItem(
          name: map['name'], bucket: map['bucket'], storage: storage);

  String getFilename() {
    if ((name == null || name!.isEmpty)) return '';
    var i = name!.lastIndexOf('/');
    return name!.substring(i + 1);
  }

  String? getDirectory() {
    if (name == null || name!.isEmpty) return '';
    var i = name!.lastIndexOf('/');
    return i == -1 ? name : name!.substring(0, i);
  }

  FirebaseStorageReference getReference() =>
      FirebaseStorageReference(storage, name);

  @override
  String toString() => name!;
}

class StorageBucketList {
  List<StorageBucketListItem> items = [];
  List<String>? prefixes = [];
  String? nextPageToken;
  StorageBucketList.fromMap({
    FirebaseStorage? storage,
    required Map<String, dynamic> map,
  }) {
    prefixes = map['prefixes'].cast<String>();
    nextPageToken = map['nextPagetoken'];
    for (var item in map['items']) {
      items.add(StorageBucketListItem.fromMap(storage, item));
    }
  }
}

class FirebaseStorage {
  final String storageBucket;
  final FirebaseAuth? auth = FirebaseAuth.instance;

  FirebaseStorage.instanceFor(this.storageBucket);

  FirebaseStorageReference ref([String? path]) {
    return FirebaseStorageReference(this, path ?? '/');
  }
}

class FirebaseStorageReference {
  static final String _firebaseStorageEndpoint =
      'https://firebasestorage.googleapis.com/v0/b/';

  final FirebaseStorage? storage;
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

  Future<void> putData(Uint8List data,
      {void Function(int progress)? onProgress}) async {
    var requestUrl = _getTargetUrl();
    var res = Completer();
    try {
      var http = storage!.auth!.httpClient!;
      var token = await storage!.auth!.tokenProvider!.idToken;
      var request = Request('POST', Uri.parse(requestUrl));
      request.headers[HttpHeaders.authorizationHeader] = 'Firebase $token';
      request.headers[HttpHeaders.contentTypeHeader] =
          'application/octet-stream';
      request.bodyBytes = data;
      var response = http.send(request);

      var uploaded = 0;
      response.asStream().listen((StreamedResponse r) {
        if (r.statusCode != 200) {
          throw Exception(
              'Server responded with error ${r.statusCode}: ${r.reasonPhrase}');
        }
        r.stream.listen(
          (List<int> chunk) {
            // Display percentage of completion
            if (onProgress != null) {
              onProgress((uploaded * 100) ~/ r.contentLength!);
            }
            uploaded += chunk.length;
          },
          onDone: () => res.complete(),
          onError: (error) => throw Exception([requestUrl, error]),
        );
      });
    } catch (ex) {
      throw Exception([requestUrl, ex]);
    }

    return res.future;
  }

  Future<void> putFile(File file,
      {void Function(int progress)? onProgress}) async {
    var requestUrl = _getTargetUrl();
    var res = Completer();
    try {
      var http = storage!.auth!.httpClient!;
      var token = await storage!.auth!.tokenProvider!.idToken;
      var data = await file.readAsBytes();
      var request = Request('POST', Uri.parse(requestUrl));
      request.headers[HttpHeaders.authorizationHeader] = 'Firebase $token';
      request.headers[HttpHeaders.contentTypeHeader] =
          lookupMimeType(p.basename(file.path)) ?? 'application/octet-stream';
      request.bodyBytes = data;
      var response = http.send(request);

      var uploaded = 0;
      response.asStream().listen((StreamedResponse r) {
        if (r.statusCode != 200) {
          throw Exception(
              'Server responded with error ${r.statusCode}: ${r.reasonPhrase}');
        }
        r.stream.listen(
          (List<int> chunk) {
            // Display percentage of completion
            if (onProgress != null) {
              onProgress((uploaded * 100) ~/ r.contentLength!);
            }
            uploaded += chunk.length;
          },
          onDone: () => res.complete(),
          onError: (error) => throw Exception([requestUrl, error]),
        );
      });
    } catch (ex) {
      throw Exception([requestUrl, ex]);
    }

    return res.future;
  }

  Future<void> putString(String data,
      {void Function(int progress)? onProgress}) async {
    var requestUrl = _getTargetUrl();
    var res = Completer();
    try {
      var http = storage!.auth!.httpClient!;
      var token = await storage!.auth!.tokenProvider!.idToken;
      var request = Request('POST', Uri.parse(requestUrl));
      request.headers[HttpHeaders.authorizationHeader] = 'Firebase $token';
      request.headers[HttpHeaders.contentTypeHeader] = 'text/plain';
      request.body = data;
      var response = http.send(request);

      var uploaded = 0;
      response.asStream().listen((StreamedResponse r) {
        if (r.statusCode != 200) {
          throw Exception(
              'Server responded with error ${r.statusCode}: ${r.reasonPhrase}');
        }
        r.stream.listen(
          (List<int> chunk) {
            // Display percentage of completion
            if (onProgress != null) {
              onProgress((uploaded * 100) ~/ r.contentLength!);
            }
            uploaded += chunk.length;
          },
          onDone: () => res.complete(),
          onError: (error) => throw Exception([requestUrl, error]),
        );
      });
    } catch (ex) {
      throw Exception([requestUrl, ex]);
    }

    return res.future;
  }

  Future<void> writeToFile(File file,
      {void Function(int progress)? onProgress}) async {
    var requestUrl = await getDownloadUrl();
    var res = Completer();
    try {
      if (file.existsSync() == false) {
        await file.create();
      }

      var http = storage!.auth!.httpClient!;
      var token = await storage!.auth!.tokenProvider!.idToken;
      var request = Request('GET', Uri.parse(requestUrl));
      request.headers[HttpHeaders.authorizationHeader] = 'Firebase $token';
      var response = http.send(request);

      var chunks = <List<int>>[];
      var downloaded = 0;

      response.asStream().listen((StreamedResponse r) {
        if (r.statusCode != 200) {
          throw Exception(
              'Server responded with error ${r.statusCode}: ${r.reasonPhrase}');
        }
        r.stream.listen(
          (List<int> chunk) {
            // Display percentage of completion
            if (onProgress != null) {
              onProgress((downloaded * 100) ~/ r.contentLength!);
            }
            chunks.add(chunk);
            downloaded += chunk.length;
          },
          onDone: () async {
            final bytes = Uint8List(r.contentLength!);
            var offset = 0;
            for (var chunk in chunks) {
              bytes.setRange(offset, offset + chunk.length, chunk);
              offset += chunk.length;
            }
            await file.writeAsBytes(bytes);
            res.complete();
          },
          onError: (error) => throw Exception([requestUrl, error]),
        );
      });
    } catch (ex) {
      throw Exception([requestUrl, ex]);
    }

    return res.future;
  }

  Future<String> getDownloadUrl() async {
    var data = await (_performFetch() as FutureOr<Map<String, dynamic>>);
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
      var http = storage!.auth!.httpClient!;
      var token = await storage!.auth!.tokenProvider!.idToken;
      var result = await http.delete(Uri.parse(requestUrl),
          headers: {'Authorization': 'Firebase $token'});
      resultContent = result.body;

      if (result.statusCode != 200) {
        throw Exception(
            'Server responded with error ${result.statusCode}: ${result.body}');
      }
    } catch (ex) {
      throw Exception([requestUrl, resultContent, ex]);
    }
  }

  String _getTargetUrl() {
    return '${_firebaseStorageEndpoint}${storage!.storageBucket}/o?name=${_getEscapedPath()}';
  }

  String _getDownloadUrl() {
    return '${_firebaseStorageEndpoint}${storage!.storageBucket}/o/${_getEscapedPath()}';
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
    reqUrl = '${_firebaseStorageEndpoint}${storage!.storageBucket}/o/?';
    reqUrl +=
        'prefix=${_pointer.isRoot ? '' : _pointer.path + Uri.encodeComponent("/")}';

    if (pageToken != null && pageToken.isNotEmpty) {
      reqUrl += '&pageToken=$pageToken';
    }

    reqUrl += '&maxResults=$maxResults';
    reqUrl += '&delimiter=${Uri.encodeComponent("/")}';

    return reqUrl;
  }

  Future<Map<String, dynamic>?> _performFetch() async {
    var requestUrl = _getDownloadUrl();
    try {
      var http = storage!.auth!.httpClient!;
      var token = await storage!.auth!.tokenProvider!.idToken;
      var result = await http.read(Uri.parse(requestUrl),
          headers: {'Authorization': 'Firebase $token'});

      return jsonDecode(result);
    } catch (ex) {
      throw Exception([requestUrl, ex]);
    }
  }

  Future<StorageBucketList> _internalRequest(String fullUrl) async {
    try {
      var http = storage!.auth!.httpClient!;
      var token = await storage!.auth!.tokenProvider!.idToken;
      var result = await http.get(Uri.parse(fullUrl),
          headers: {'Authorization': 'Firebase $token'});

      if (result.statusCode != 200) {
        throw Exception(
            'Server responded with error ${result.statusCode}: ${result.body}');
      }
      var bucket = StorageBucketList.fromMap(
        storage: storage,
        map: jsonDecode(result.body),
      );
      return bucket;
    } catch (ex) {
      throw Exception([fullUrl, ex]);
    }
  }
}
