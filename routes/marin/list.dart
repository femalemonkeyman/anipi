import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';

const String baseUrl = 'https://marin.moe/anime';

Future<frog.Response> onRequest(frog.RequestContext context) async {
  if (context.request.uri.queryParameters.containsKey("malid")) {
    final Dio dio = Dio();
    final Map syncResponse = (await dio.get(
            'https://api.malsync.moe/mal/anime/${context.request.uri.queryParameters['malid']}'))
        .data;
    final String id = syncResponse['Sites']['Marin'].keys.first;
    final List<String> headers = await getToken(dio);
    final Map info = (await dio.post(
      '$baseUrl/$id',
      options: Options(
        headers: {
          'Origin': 'https://marin.moe/',
          'Referer': 'https://marin.moe/anime/$id',
          'Cookie':
              '__ddg1=;__ddg2_=; XSRF-TOKEN=${headers[0]}; marin_session=${headers[1]}',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
          'x-inertia': true,
          'x-inertia-version': '884345c4d568d16e3bb2fb3ae350cca9',
          'x-requested-with': 'XMLHttpRequest',
          'x-xsrf-token': headers[0].replaceAll('%3D', '='),
        },
      ),
    ))
        .data;
    List episodes = [];
    for (Map i in info['props']['episode_list']['data']) {
      episodes.add({
        'episode': i['sort'],
        'title': i['title'],
        'id': '$id/${i['sort']}'
      });
    }
    return frog.Response.json(body: episodes);
  }
  return frog.Response(body: 'Needs a malid');
}

Future<List<String>> getToken(Dio dio) async {
  final String headers = (await Dio().get(
    'https://marin.moe/anime',
    options: Options(
      headers: {
        'Referer': 'https://marin.moe/anime',
        'Cookie': '__ddg1_=;__ddg2_=;',
      },
    ),
  ))
      .headers
      .toString();

  return [
    headers.split('XSRF-TOKEN=')[1].split(';')[0],
    headers.split('marin_session=')[1].split(';')[0]
  ];
}
