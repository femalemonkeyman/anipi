import 'dart:convert';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

const String zoro = "https://aniwatch.to/";

Future<frog.Response> onRequest(frog.RequestContext context) async {
  final Options options = Options(responseType: ResponseType.plain);
  if (context.request.uri.queryParameters.containsKey('id')) {
    final String? id = context.request.uri.queryParameters['id'];
    final Element server = parse(
      jsonDecode(
        (await Dio().get(
          '${zoro}ajax/v2/episode/servers?episodeId=$id',
          options: options,
        ))
            .data,
      )['html'],
    )
        .getElementsByClassName("item server-item")
        .firstWhere((element) => element.text.contains('Vid'));
    final Map link = jsonDecode(
      (await Dio().get(
        '${zoro}ajax/v2/episode/sources?id=${server.attributes['data-id']}',
        options: options,
      ))
          .data,
    );
    final Map<String, dynamic> sources = jsonDecode(
      (await Dio().get(
              'https://megacloud.tv/embed-2/ajax/e-1/getSources?id=${link['link'].split('e-1/')[1].split('?')[0]}',
              options: options))
          .data,
    );
    if (sources['encrypted']) {
      String key = '';
      int offset = 0;
      for (final List i in jsonDecode((await Dio().get(
              'https://raw.githubusercontent.com/enimax-anime/key/e6/key.txt'))
          .data)) {
        key += sources['sources'].substring(i.first - offset, i.last - offset);
        sources['sources'] = sources['sources'].toString().replaceRange(
              i.first - offset,
              i.last - offset,
              '',
            );
        offset += ((i.last as int) - (i.first as int));
      }
      sources['sources'] = jsonDecode(decrypt(sources['sources'], key));
    }
    sources['tracks'].removeWhere((element) => element['kind'] != 'captions');
    return frog.Response.json(body: sources);
  }
  return frog.Response(body: "Needs an episode id");
}

String decrypt(final String encrypted, final String passphrase) {
  final Uint8List encryptedBytesWithSalt = base64.decode(encrypted);
  final Uint8List encryptedBytes =
      encryptedBytesWithSalt.sublist(16, encryptedBytesWithSalt.length);
  final (key, iv) =
      deriveKeyAndIV(passphrase, encryptedBytesWithSalt.sublist(8, 16));
  return Encrypter(AES(key, mode: AESMode.cbc, padding: "PKCS7"))
      .decrypt64(base64.encode(encryptedBytes), iv: iv);
}

(Key, IV) deriveKeyAndIV(final String passphrase, final Uint8List salt) {
  final password = Uint8List.fromList(passphrase.codeUnits);
  final Uint8List concatenatedHashes = Uint8List(48);
  Uint8List currentHash = Uint8List(0);
  for (int i = 0; i < 48; i += currentHash.length) {
    currentHash =
        Uint8List.fromList(md5.convert(currentHash + password + salt).bytes);
    concatenatedHashes.setRange(i, i + currentHash.length, currentHash);
  }
  return (
    Key(concatenatedHashes.sublist(0, 32)),
    IV(concatenatedHashes.sublist(32, 48)),
  );
}
