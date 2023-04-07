import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dart_frog/dart_frog.dart' as frog;

Future<frog.Response?> onRequest(frog.RequestContext context) async {
  //name.split(pattern).getRange(0, 3);
  if (context.request.uri.queryParameters.containsKey('name')) {
    final json = await Dio().post(
      'https://search.htv-services.com/',
      data: jsonEncode(
        {
          'search_text':
              (context.request.uri.queryParameters['name']!.split(' ').length >
                      3)
                  ? context.request.uri.queryParameters['name']
                      ?.split(' ')
                      .getRange(0, 3)
                      .join(' ')
                      .replaceAll(':', '')
                  : context.request.uri.queryParameters['name'],
          // "${name.split(" ")[0]} ${name.split(" ")[1]} ${name.split(" ")[2]}"
          //     .replaceAll(":", ""),
          'tags': [],
          'tags-mode': 'AND',
          'brands': [],
          'blacklist': [],
          'order_by': '',
          'ordering': '',
          "page": 0
        },
      ),
    );
    if (json.data['nbHits'] > 0) {
      final List results = jsonDecode(json.data['hits']);

      List videos = [];

      for (var i in results) {
        Response v = await Dio().get(
          "https://hanime.tv/api/v8/video?id=${i['id']}",
        );
        videos.add(v.data);
      }

      return frog.Response.json(
        body: List.generate(
          videos.length,
          (index) {
            return {
              "title": (videos[index])['hentai_video']['name'],
              "number": "Episode: ${index + 1}",
              "sources": [
                {
                  "url": videos[index]['videos_manifest']['servers'][0]
                      ['streams'][1]['url']
                },
              ],
            };
          },
        ),
      );
    }
  }
  return frog.Response(body: 'Needs a name', statusCode: 69420);
}
