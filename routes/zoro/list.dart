import 'dart:convert';
import 'dart:isolate';
import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

const String zoro = "https://aniwatch.to/";

Future<frog.Response> onRequest(frog.RequestContext context) async {
  print(Isolate.current.debugName);
  if (context.request.uri.queryParameters.containsKey('malid')) {
    try {
      final Map syncResponse = (await Dio().get(
        "https://api.malsync.moe/mal/anime/${context.request.uri.queryParameters['malid']}",
      ))
          .data;
      final Response html = await Dio().get(
        '${zoro}ajax/v2/episode/list/${syncResponse['Sites']['Zoro'].keys.first}',
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
      final Document episodeList = parse(jsonDecode(html.data)['html']);
      List episodes = [];
      final List elements =
          episodeList.getElementsByClassName('ssl-item  ep-item');
      for (Element i in elements) {
        episodes.add(
          {
            "episode": i.attributes['data-number'],
            "title": i.attributes['title'],
            'id': i.attributes['data-id'],
          },
        );
      }
      return frog.Response.json(body: episodes);
    } catch (e) {
      print(e);
      return frog.Response(
          body: "Something did a fucky wuckie", statusCode: 500);
    }
  }
  return frog.Response(body: "Needs a malId");
}
