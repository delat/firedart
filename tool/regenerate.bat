@echo off

protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %GOOGLEAPIS%\google\rpc\status.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %PROTOBUF%\src\google\protobuf\any.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %PROTOBUF%\src\google\protobuf\empty.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %PROTOBUF%\src\google\protobuf\struct.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %PROTOBUF%\src\google\protobuf\timestamp.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %PROTOBUF%\src\google\protobuf\wrappers.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %GOOGLEAPIS%\google\firestore\v1\common.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %GOOGLEAPIS%\google\firestore\v1\write.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %GOOGLEAPIS%\google\firestore\v1\query.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %GOOGLEAPIS%\google\firestore\v1\firestore.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %GOOGLEAPIS%\google\firestore\v1\document.proto
protoc --dart_out=grpc:lib/generated -I%PROTOBUF%/src -I%GOOGLEAPIS% %GOOGLEAPIS%\google\type\latlng.proto
dartfmt -w lib\generated