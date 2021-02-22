import 'dart:core';

class FirebaseMetaData {
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

  FirebaseMetaData(
      {this.bucket,
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
      this.contentDisposition});

  factory FirebaseMetaData.fromMap(Map<String, dynamic> map) =>
      FirebaseMetaData(
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
