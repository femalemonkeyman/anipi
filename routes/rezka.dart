import 'dart:convert';
import 'package:chitose/chitose.dart';
import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';

Future<frog.Response> onRequest(frog.RequestContext context) async {
  if (context.request.uri.queryParameters.containsKey("url")) {
    final Response rezka = await Dio().get(
      context.request.uri.queryParameters['url']!,
    );
    final Document html = parse(rezka.data);
    final Map sources = jsonDecode((await Dio().post(
      "https://rezka.ag/ajax/get_cdn_series/",
      data: FormData.fromMap({
        "id": html
            .getElementsByClassName("b-translator__item active")[0]
            .attributes['data-id'],
        "translator_id": html
            .getElementsByClassName("b-translator__item active")[0]
            .attributes['data-translator_id'],
        "action": "get_movie",
      }),
    ))
        .data);
    final List trashList = ["@", "#", "!", "^", "\$"];
    List remove = [];
    for (List i in trashList.product(2)) {
      remove.add(base64Encode(utf8.encode(i.join())));
    }
    for (List i in trashList.product(3)) {
      remove.add(base64Encode(utf8.encode(i.join())));
    }
    String decode =
        sources['url'].toString().replaceAll('#h', '').split('//_//').join('');
    for (String i in remove) {
      decode = decode.replaceAll(i, '');
    }
    sources['url'] = Latin1Codec().decode(base64Decode(decode));
    return frog.Response.json(
      body: sources,
    );
  }
  return frog.Response(body: "Dunno yet");
}
