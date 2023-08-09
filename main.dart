import 'dart:io';
import 'dart:isolate';
import 'package:dart_frog/dart_frog.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  // 1. Execute any custom code prior to starting the server...

  for (var i = 1; i < 6; i++) {
    Isolate.spawn(startServer, [handler, ip, port], debugName: "thread: $i");
  }
  // 2. Use the provided `handler`, `ip`, and `port` to create a custom `HttpServer`.
  // Or use the Dart Frog serve method to do that for you.
  return serve(handler, ip, port, shared: true);
}

void startServer(List args) {
  serve(args[0], args[1], args[2], shared: true);
}
