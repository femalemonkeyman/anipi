import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

Future<frog.Response> onRequest(frog.RequestContext context) async {
  final Options options = Options(responseType: ResponseType.plain);
  if (context.request.uri.queryParameters.containsKey('id')) {
    final String? id = context.request.uri.queryParameters['id'];
    final Response servers = await Dio().get(
      'https://zoro.to/ajax/v2/episode/servers?episodeId=$id',
      options: options,
    );
    final Document html = parse(
      jsonDecode(
        servers.data,
      )['html'],
    );
    Element server = html
        .getElementsByClassName("item server-item")
        .firstWhere((element) => element.text.contains('Vid'));
    final Map link = jsonDecode((await Dio().get(
      'https://zoro.to/ajax/v2/episode/sources?id=${server.attributes['data-id']}',
      options: options,
    ))
        .data);
    Map sources = jsonDecode(
      (await Dio().get(
              'https://rapid-cloud.co/ajax/embed-6/getSources?id=${link['link'].split('6/')[1].split('?')[0]}',
              options: options))
          .data,
    );
    final String key = (await Dio().get(
            'https://raw.githubusercontent.com/enimax-anime/key/e6/key.txt'))
        .data;
    if (sources['encrypted']) {
      sources['sources'] = decryptAESCryptoJS(sources['sources'], key);
      sources['sourcesBackup'] =
          decryptAESCryptoJS(sources['sourcesBackup'], key);
    }
    return frog.Response.json(body: sources);
  }
  return frog.Response(body: "Needs an episode id");
}

String decryptAESCryptoJS(final String encrypted, final String passphrase) {
  try {
    Uint8List encryptedBytesWithSalt = base64.decode(encrypted);
    Uint8List encryptedBytes =
        encryptedBytesWithSalt.sublist(16, encryptedBytesWithSalt.length);
    final salt = encryptedBytesWithSalt.sublist(8, 16);
    final List<Uint8List> keyndIV = deriveKeyAndIV(passphrase, salt);
    final key = encrypt.Key(keyndIV[0]);
    final iv = encrypt.IV(keyndIV[1]);
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: "PKCS7"));
    final decrypted =
        encrypter.decrypt64(base64.encode(encryptedBytes), iv: iv);
    return decrypted;
  } catch (error) {
    throw error;
  }
}

List<Uint8List> deriveKeyAndIV(final String passphrase, final Uint8List salt) {
  var password = createUint8ListFromString(passphrase);
  Uint8List concatenatedHashes = Uint8List(0);
  Uint8List currentHash = Uint8List(0);
  Uint8List preHash = Uint8List(0);

  while (concatenatedHashes.length < 48) {
    if (currentHash.length > 0)
      preHash = Uint8List.fromList(currentHash + password + salt);
    else
      preHash = Uint8List.fromList(password + salt);
    currentHash = Uint8List.fromList(md5.convert(preHash).bytes);
    concatenatedHashes = Uint8List.fromList(concatenatedHashes + currentHash);
  }
  return [
    concatenatedHashes.sublist(0, 32),
    concatenatedHashes.sublist(32, 48),
  ];
}

Uint8List createUint8ListFromString(final String s) {
  Uint8List ret = Uint8List(s.length);
  for (var i = 0; i < s.length; i++) {
    ret[i] = s.codeUnitAt(i);
  }
  return ret;
}

Uint8List genRandomWithNonZero(final int seedLength) {
  final Random random = Random.secure();
  const int randomMax = 245;
  final Uint8List uint8list = Uint8List(seedLength);
  for (int i = 0; i < seedLength; i++) {
    uint8list[i] = random.nextInt(randomMax) + 1;
  }
  return uint8list;
}
