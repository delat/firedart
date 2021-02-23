import 'dart:core';

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
  final String cacheControl;

  /// Served as the 'Cache-Disposition' header on object download.
  final String contentDisposition;

  /// Served as the 'Content-Encoding' header on object download.
  final String contentEncoding;

  /// Served as the 'Content-Language' header on object download.
  final String contentLanguage;

  /// Served as the 'Content-Type' header on object download.
  final String contentType;

  /// Additional user-defined custom metadata.
  final Map<String, String> customMetadata;

  /// Returns the settable metadata as a [Map].
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'cacheControl': cacheControl,
      'contentDisposition': contentDisposition,
      'contentEncoding': contentEncoding,
      'contentLanguage': contentLanguage,
      'contentType': contentType,
      'customMetadata': customMetadata,
    };
  }
}

class FullMetadata {
  // [JsonProperty("bucket")]
  String bucket;
  // [JsonProperty("generation")]
  String generation;
  // [JsonProperty("metageneration")]
  String metaGeneration;
  // [JsonProperty("fullPath")]
  String fullPath;
  // [JsonProperty("name")]
  String name;
  // [JsonProperty("size")]
  int size;
  // [JsonProperty("contentType")]
  String contentType;
  // [JsonProperty("timeCreated")]
  DateTime timeCreated;
  // [JsonProperty("updated")]
  DateTime updated;
  // [JsonProperty("md5Hash")]
  String md5Hash;
  // [JsonProperty("contentEncoding")]
  String contentEncoding;
  // [JsonProperty("contentDisposition")]
  String contentDisposition;

  FullMetadata({
    this.bucket,
    this.generation,
    this.metaGeneration,
    this.fullPath,
    this.name,
    this.size,
    this.contentType,
    this.timeCreated,
    this.updated,
    this.md5Hash,
    this.contentEncoding,
    this.contentDisposition,
  });

  factory FullMetadata.fromMap(Map<String, dynamic> map) => FullMetadata(
        bucket: map['bucket'],
        generation: map['generation'],
        metaGeneration: map['metageneration'],
        fullPath: map['fullPath'],
        name: map['name'],
        size: map['size'],
        contentType: map['conentType'],
        timeCreated: map['timeCreated'],
        updated: map['updated'],
        md5Hash: map['md5Hash'],
        contentEncoding: map['contentEncoding'],
        contentDisposition: map['contentDisposition'],
      );
}
