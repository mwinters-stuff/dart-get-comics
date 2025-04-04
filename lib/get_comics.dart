import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get_comics/email_sender.dart';
import 'package:get_comics/fetch_comic.dart';
import 'package:yaml/yaml.dart';

Future<bool> getComics(
    FetchComic fetchComic, YamlMap config, YamlList comics) async {
  String? smtpUsername;
  String? smtpPassword;

  if (config.keys.contains('smtp-username')) {
    smtpUsername = config['smtp-username'];
    smtpPassword = config['smtp-password'];
  }

  var sender = EmailSender(config['smtp-server'], config['smtp-port'],
      smtpUsername, smtpPassword, config['sender']);

  try {
    for (var comic in comics) {
      var url = comic[comic.keys.first]['url'];
      var to = <String>[];
      comic[comic.keys.first]['to'].forEach((e) => to.add(e));
      String? dateSepChar;
      if (comic[comic.keys.first].keys.contains('date-seperator')) {
        dateSepChar = comic[comic.keys.first]['date-seperator'];
      }

      for (var i = 0; i < 5; i++) {
        if (!await fetchComic.fetchComic(
            url.toString().trim(), to, Dio(), sender, dateSepChar)) {
          print(
              'Fetch ${url.toString().trim()} failed. Sleeping 62 seconds, step $i');
          sleep(Duration(seconds: 62));
        } else {
          break;
        }
      }
    }
  } finally {
    sender.disconnect();
  }
  return true;
}
