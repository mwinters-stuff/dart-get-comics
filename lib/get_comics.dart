import 'package:dio/dio.dart';
import 'package:get_comics/email_sender.dart';
import 'package:get_comics/fetch_comic.dart';

Future<bool> getComics(FetchComic fetchComic, config, comics) async {
  var sender = EmailSender(config['smtp-server'], config['smtp-port'],
      config['smtp-username'], config['smtp-password'], config['sender']);

  try {
    for (var comic in comics) {
      var url = comic[comic.keys.first]['url'];
      var to = <String>[];
      comic[comic.keys.first]['to'].forEach((e) => to.add(e));
      String? dateSepChar;
      if (comic[comic.keys.first].keys.contains('date-seperator')) {
        dateSepChar = comic[comic.keys.first]['date-seperator'];
      }

      if (!await fetchComic.fetchComic(url, to, Dio(), sender, dateSepChar)) {
        return false;
      }
    }
  } finally {
    sender.disconnect();
  }
  return true;
}
