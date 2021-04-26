import 'package:firedart/auth/firebase_auth.dart';

import 'firestore_gateway.dart';
import 'models.dart';

class Firestore {
  /* Singleton interface */
  static Firestore? _instance;
  static Firestore get instance {
    if (_instance == null) {
      throw Exception(
          "Firestore hasn't been initialized. Please call Firestore.initialize() before using it.");
    }
    return _instance!;
  }

  /* Instance interface */
  final FirestoreGateway _gateway;

  factory Firestore(String projectId, {String? databaseId}) {
    if (_instance != null) {
      throw Exception('Firestore instance was already initialized');
    }
    _instance = Firestore._(projectId,
        databaseId: databaseId, auth: FirebaseAuth.instance);
    return _instance!;
  }

  Firestore._(String projectId, {String? databaseId, FirebaseAuth? auth})
      : _gateway =
            FirestoreGateway(projectId, databaseId: databaseId, auth: auth),
        assert(projectId.isNotEmpty);

  Reference reference(String path) => Reference.create(_gateway, path);

  CollectionReference collection(String path) =>
      CollectionReference(_gateway, path);

  DocumentReference document(String path) => DocumentReference(_gateway, path);
}
