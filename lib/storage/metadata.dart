import 'dart:core';
import 'dart:convert';

class SettableMetadata {
  /// Creates a new [SettableMetadata] instance.
  SettableMetadata({
    this.cacheControl,
    this.contentDisposition,
    this.contentEncoding,
    this.contentLanguage,
    this.contentType,
    this.customMetadata,
  });

  /// Served as the 'Cache-Control' header on object download.
  final String? cacheControl;

  /// Served as the 'Cache-Disposition' header on object download.
  final String? contentDisposition;

  /// Served as the 'Content-Encoding' header on object download.
  final String? contentEncoding;

  /// Served as the 'Content-Language' header on object download.
  final String? contentLanguage;

  /// Served as the 'Content-Type' header on object download.
  final String? contentType;

  /// Additional user-defined custom metadata.
  final Map<String, String>? customMetadata;

  /// Returns the settable metadata as a [Map].
  Map<String, String?> asMap() {
    return <String, String?>{
      'cacheControl': cacheControl,
      'contentDisposition': contentDisposition,
      'contentEncoding': contentEncoding,
      'contentLanguage': contentLanguage,
      'contentType': contentType,
      'customMetadata':
          customMetadata != null ? jsonEncode(customMetadata) : null,
    };
  }
}

/// The result of calling [getMetadata] on a storage object reference.
class FullMetadata {
  // ignore: public_member_api_docs
  FullMetadata(this._metadata);

  final Map<String, dynamic>? _metadata;

  /// The bucket this object is contained in.
  String? get bucket {
    return _metadata!['bucket'];
  }

  /// Served as the 'Cache-Control' header on object download.
  String? get cacheControl {
    return _metadata!['cacheControl'];
  }

  /// Served as the 'Content-Disposition' HTTP header on object download.
  String? get contentDisposition {
    return _metadata!['contentDisposition'];
  }

  /// Served as the 'Content-Encoding' header on object download.
  String? get contentEncoding {
    return _metadata!['contentEncoding'];
  }

  /// Served as the 'Content-Language' header on object download.
  String? get contentLanguage {
    return _metadata!['contentLanguage'];
  }

  /// Served as the 'Content-Type' header on object download.
  String? get contentType {
    return _metadata!['contentType'];
  }

  /// Custom metadata set on this storage object.
  Map<String, String>? get customMetadata {
    return _metadata!['customMetadata'] == null
        ? null
        : Map<String, String>.from(_metadata!['customMetadata']);
  }

  /// The full path of this object.
  String? get fullPath {
    return _metadata!['fullPath'];
  }

  /// The object's generation.
  String? get generation {
    return _metadata!['generation'];
  }

  /// The object's metadata generation.
  String? get metadataGeneration {
    return _metadata!['metadataGeneration'];
  }

  /// A Base64-encoded MD5 hash of the object being uploaded.
  String? get md5Hash {
    return _metadata!['md5Hash'];
  }

  /// The object's metageneration.
  String? get metageneration {
    return _metadata!['metageneration'];
  }

  /// The short name of this object, which is the last component of the full path.
  ///
  /// For example, if fullPath is 'full/path/image.png', name is 'image.png'.
  String? get name {
    return _metadata!['name'];
  }

  /// The size of this object, in bytes.
  int? get size {
    return int.tryParse(_metadata!['size']);
  }

  /// A DateTime representing when this object was created.
  DateTime? get timeCreated {
    return _metadata!['timeCreated'] == null
        ? null
        : DateTime.tryParse(_metadata!['timeCreated']);
  }

  /// A DateTime representing when this object was updated.
  DateTime? get updated {
    return _metadata!['updated'] == null
        ? null
        : DateTime.tryParse(_metadata!['updated']);
  }
}
