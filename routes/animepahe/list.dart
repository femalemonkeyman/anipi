import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';
import 'package:html/parser.dart';

Future<frog.Response> onRequest(frog.RequestContext context) async {
  if (context.request.uri.queryParameters.containsKey("malid")) {
    final Map malsync = (await Dio().get(
            'https://api.malsync.moe/mal/anime/${context.request.uri.queryParameters['malid']}'))
        .data;
    final String id = parse(
      (await Dio().get(
              'https://animepahe.com/a/${malsync['Sites']?['animepahe'].keys.first}'))
          .data,
    )
        .head!
        .getElementsByTagName('script')
        .first
        .text
        .split('let id = "')[1]
        .split('";')[0];
    final String link =
        'https://animepahe.ru/api?m=release&id=$id&sort=episode_asc';
    final Map anime = (await Dio().get(link)).data;
    if (anime['last_page'] > 1) {
      final List<Future<Response<Map>>> requests = [];
      for (int i = 2; i <= anime['last_page']; i++) {
        requests.add(
          Dio().get('$link&page=$i'), //.data['data']
        );
      }
      for (Response i in await Future.wait(requests)) {
        anime['data'].addAll(i.data['data']);
      }
    }
    final List<Map> data = [];
    for (Map i in anime['data']) {
      data.add({
        'title': i['title'],
        'number': i['episode'],
        'id': '$id/${i['session']}',
      });
    }
    return frog.Response.json(body: data);
  }
  return frog.Response(body: 'Needs a malid');
}
