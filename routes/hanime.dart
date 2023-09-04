import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:string_similarity/string_similarity.dart';

Future<frog.Response?> onRequest(frog.RequestContext context) async {
  if (context.request.uri.queryParameters.containsKey('name')) {
    final name = context.request.uri.queryParameters['name'];
    final Map json = (await Dio().post(
      "https://search.htv-services.com/",
      data: jsonEncode(
        {
          "search_text": name!
              .split(" ")
              .take(2)
              .join(' ')
              .replaceAll(RegExp('[^A-Za-z0-9- !]'), ''),
          "tags": [],
          "tags-mode": "AND",
          "brands": [],
          "blacklist": [],
          "order_by": "",
          "ordering": "",
          "page": 0
        },
      ),
    ))
        .data;
    if (json['nbHits'] > 0) {
      final List requests = await Future.wait(
        [
          for (Map i in jsonDecode(json['hits']))
            if (name.bestMatch([i['name'], ...i['titles']]).bestMatch.rating! >
                0.52)
              Dio().get(
                "https://hanime.tv/api/v8/video?id=${i['id']}",
              ),
        ],
      );
      return frog.Response.json(
        body: [
          for (Response i in requests)
            {
              "title": i.data['hentai_video']['name'],
              'number':
                  i.data['hentai_video']['slug'].split('-').last.toString(),
              "sources": [
                {
                  "url": i.data['videos_manifest']['servers'][0]['streams'][1]
                      ['url']
                },
              ],
            }
        ],
      );
    }
  }
  return frog.Response(body: 'Needs a name', statusCode: 69420);
}
