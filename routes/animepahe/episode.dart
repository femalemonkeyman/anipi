import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:js_unpack/js_unpack.dart';

Future<frog.Response> onRequest(frog.RequestContext context) async {
  if (context.request.uri.queryParameters.containsKey('id')) {
    final yes = parse(
      (await Dio().get(
        'https://animepahe.ru/play/${context.request.uri.queryParameters['id']}',
        options: Options(
          headers: {
            'referer': 'https://animepahe.ru',
          },
        ),
      ))
          .data,
    );
    final List sources = [];
    for (Element i in yes.body!
        .getElementsByTagName('button')
        .where((element) => element.attributes.containsKey('data-src'))) {
      if (i.attributes['data-src']?.contains('kwik') ?? false) {
        Document arr = parse((await Dio().get(
          i.attributes['data-src']!,
          options: Options(
            headers: {
              'referer': 'https://animepahe.ru',
            },
          ),
        ))
            .data);
        print(
          arr
              .getElementsByTagName('script')
              .where((element) => element.text.contains('eval'))
              .first
              .text,
        );
        // print(JsUnpack.detect(
        //   arr
        //       .getElementsByTagName('script')
        //       .where((element) => element.text.contains('eval'))
        //       .first
        //       .text,
        // ));
        print(JsUnpack(
          '\r${arr.getElementsByTagName('script').where((element) => element.text.contains('eval')).first.text}',
        ).unpack());
        break;
      }
    }
  }

  return frog.Response(body: 'Needs an id');
}
