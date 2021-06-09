import 'dart:io' as io;

import 'package:dcli/dcli.dart';
import 'package:get_comics/emal_sender.dart';
import 'package:universal_html/html.dart';
import 'package:universal_html/parsing.dart';

Future<bool> fetchComic(String comicUrl, List<String> to,
    EmailSender emailSender, String? dateSepChar) async {
  var now = DateTime.now().add(Duration(days: -1));

  var uri = Uri.tryParse(comicUrl);
  if (uri == null) {
    print('uri error');
    return false;
  }
  var pathSegments = <String>[];
  pathSegments.addAll(uri.pathSegments);
  if (dateSepChar != null) {
    pathSegments.add(
        '${now.year.toString()}$dateSepChar${now.month.toString().padLeft(2, '0')}$dateSepChar${now.day.toString().padLeft(2, '0')}');
  } else {
    pathSegments.add(now.year.toString());
    pathSegments.add(now.month.toString().padLeft(2, '0'));
    pathSegments.add(now.day.toString().padLeft(2, '0'));
  }

  var url = Uri(
          host: uri.host,
          pathSegments: pathSegments,
          port: uri.port,
          query: uri.query,
          scheme: uri.scheme)
      .toString();

  // String url =
  //     "$comicUrl/${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
  var comicFile = createTempFilename();
  print('url $url to $comicFile');
  fetch(url: url, saveToPath: comicFile);

  final contents = io.File(comicFile).readAsStringSync();
  final htmlDocument = parseHtmlDocument(contents);

  var image = '';
  var title = htmlDocument.title;
  htmlDocument.getElementsByTagName('meta').forEach((element) {
    if (element is MetaElement) {
      if (element.attributes.containsKey('name') &&
          element.attributes['name'] == 'twitter:image') {
        image = element.content;
        return;
      }
    }
  });
  print('$title -> $image to $to');
  if (title.isNotEmpty && image.isNotEmpty) {
    return await emailSender.send(to, title, image);
  }
  return false;
}
