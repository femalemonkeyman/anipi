import 'dart:convert';
import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

Future<frog.Response> onRequest(frog.RequestContext context) async {
  if (context.request.uri.queryParameters.containsKey('id')) {
    final String? id = context.request.uri.queryParameters['id'];
    final Response servers = await Dio().get(
      'https://zoro.to/ajax/v2/episode/servers?episodeId=$id',
      options: Options(
        responseType: ResponseType.plain,
      ),
    );
    final Document html = parse(
      jsonDecode(
        servers.data,
      )['html'],
    );
    List sources = [];
    for (Element i in html.getElementsByClassName("item server-item")) {
      sources.add(
        {
          'type': i.attributes['data-type'],
          'id': i.attributes['data-id'],
        },
      );
    }
    return frog.Response.json(body: sources);
  }
  return frog.Response(body: "Needs an episode id");
}
