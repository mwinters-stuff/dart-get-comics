import 'dart:io' as io;

import 'package:get_comics/emal_sender.dart';
import 'package:get_comics/fetch_comic.dart';

Future<bool> getComics(config, comics) async {
  var sender = EmailSender(config['smtp-server'], config['smtp-port'],
      config['smtp-username'], config['smtp-password'], config['sender']);

  try {
    for (var comic in comics) {
      var url = comic[comic.keys.first]['url'];
      var to = <String>[];
      comic[comic.keys.first]['to'].forEach((e) => to.add(e));
      String? dateSepChar;
      if (comic[comic.keys.first].keys.contains['date-seperator']) {
        dateSepChar = comic[comic.keys.first]['date-seperator'];
      }

      if (!await fetchComic(url, to, sender, dateSepChar)) {
        return false;
      }
    }
  } finally {
    sender.disconnect();
  }
  return true;
}
