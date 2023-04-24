import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';
import 'list.dart';

Future<frog.Response> onRequest(frog.RequestContext context) async {
  if (context.request.uri.queryParameters.containsKey("id")) {
    final Dio dio = Dio();
    final List<String> headers = await getToken(dio);
    final Map info = (await dio.post(
      '$baseUrl/${context.request.uri.queryParameters['id']}',
      options: Options(
        headers: {
          'Origin': 'https://marin.moe/',
          'Referer':
              'https://marin.moe/anime/${context.request.uri.queryParameters['id']}',
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

    return frog.Response.json(body: info['props']['video']['data']['mirror']);
  }
  return frog.Response(body: 'Needs an id');
}
