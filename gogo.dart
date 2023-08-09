import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:html/parser.dart';

void main() async {
  final iv = IV.fromUtf8("3134003223491201");
  const String gogo = 'https://gogoanime.cl';
  final episode = parse(
    (await Dio().get('$gogo/mahoutsukai-no-yome-season-2-episode-7')).data,
  ).body?.getElementsByClassName('active')[0].attributes['data-video'];
  String params = String.fromCharCodes(AES(
    Key.fromUtf8('37911490979715163134003223491201'),
    mode: AESMode.cbc,
  ).decrypt(
    Encrypted.fromBase64((await Dio().get(episode!))
        .data
        .split('data-value=\"')[1]
        .split('\"><')[0]),
    iv: iv,
  ));
  final String encrypt = params.split('&')[0];
  params = params.replaceAll(
    '$encrypt&',
    '${AES(Key.fromUtf8('37911490979715163134003223491201'), mode: AESMode.cbc).encrypt(
          Uint8List.fromList(encrypt.codeUnits),
          iv: iv,
        ).base64}&',
  );
  final Map sources = jsonDecode(String.fromCharCodes(
    AES(Key.fromUtf8('54674138327930866480207815084989'), mode: AESMode.cbc)
        .decrypt(
      Encrypted.fromBase64(
        jsonDecode((await Dio().get(
          'https://playtaku.online/encrypt-ajax.php?id=$params&alias=$encrypt',
          options: Options(
            headers: {
              'referer': episode,
              'host': 'playtaku.online',
              'x-requested-with': 'XMLHttpRequest'
            },
          ),
        ))
            .data)['data'],
      ),
      iv: iv,
    ),
  ));
  print('https://playtaku.online/encrypt-ajax.php?id=$params&alias=$encrypt');
  print(sources);
}
