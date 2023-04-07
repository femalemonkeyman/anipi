import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';

Future<frog.Response?> onRequest(frog.RequestContext context) async {
  final String zoro = "https://zoro.to/";
  if (context.request.uri.queryParameters.containsKey('malid')) {
    final Map syncResponse = (await Dio().get(
      "https://api.malsync.moe/mal/anime/${context.request.uri.queryParameters['malid']}",
    ))
        .data;
    final Map episodeList = (await Dio().get(
            '${zoro}ajax/v2/episode/list/${syncResponse['Sites']['Zoro'].keys.first}'))
        .data;
    return frog.Response(
      body: episodeList['html'].toString(),
    );
  }
  return frog.Response(body: "Needs a mal ID");
}
