import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class TestReply {
  TestReply(this.data, {this.status = 200});
  final Object? data;
  final int status;
}

class TestAdapter implements HttpClientAdapter {
  TestAdapter(this.handle);
  final Future<TestReply> Function(RequestOptions) handle;
  final List<RequestOptions> requests = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = await handle(options);
    if (options.responseType == ResponseType.bytes) {
      return ResponseBody.fromBytes(
        (reply.data as List).cast<int>(),
        reply.status,
        headers: {
          Headers.contentTypeHeader: ['image/png'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(reply.data),
      reply.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
