import 'package:clock/clock.dart';

import 'package:dio/dio.dart';
import 'package:get_comics/email_sender.dart';
import 'package:html/parser.dart';

class FetchComic {
  String? makeComicUrl(String comicUrl, String? dateSepChar) {
    var now = clock.now().add(Duration(days: -1));

    var uri = Uri.tryParse(comicUrl);
    if (uri == null) {
      print('uri parse error');
      return null;
    }
    var pathSegments = <String>[];
    pathSegments.addAll(uri.pathSegments);
    if (dateSepChar != null) {
      pathSegments.add(
        '${now.year.toString()}$dateSepChar${now.month.toString().padLeft(2, '0')}$dateSepChar${now.day.toString().padLeft(2, '0')}',
      );
    } else {
      pathSegments.add(now.year.toString());
      pathSegments.add(now.month.toString().padLeft(2, '0'));
      pathSegments.add(now.day.toString().padLeft(2, '0'));
    }

    return Uri(
      host: uri.host,
      pathSegments: pathSegments,
      port: uri.port,
      query: uri.query,
      scheme: uri.scheme,
    ).toString();
  }

  Future<String> getComicContent(Dio dio, String url) async {
    print('url $url');

    final response = await dio.get(url);
    return response.data.toString();
  }

  Future<bool> fetchComic(
    String comicUrl,
    List<String> to,
    Dio dio,
    EmailSender emailSender,
    String? dateSepChar,
  ) async {
    final url = makeComicUrl(comicUrl, dateSepChar);
    if (url == null) {
      return false;
    }

    final contents = await getComicContent(dio, url);

    final htmlDocument = parse(contents);

    final section = htmlDocument
        .querySelector("section[data-sentry-component=\"ShowComicViewer\"]");
    if (section == null) {
      throw Exception("Comic image section URL not found");
    }

    final imageElement = section.querySelector('img.Comic_comic__image__6e_Fw');
    if (imageElement == null) {
      throw Exception("Comic image URL not found");
    }

    // Extract the correct src URL for width=1400 from srcset
    String? srcSet = imageElement.attributes['srcset'];
    if (srcSet != null) {
      List<String> sources = srcSet.split(",");
      for (var source in sources) {
        var parts = source.trim().split(" ");
        if (parts.length > 1 && parts[1].contains("1400w")) {
          var image = parts[0];
          String? title = htmlDocument.getElementsByTagName('title').first.text;
          if (image.isNotEmpty) {
            print('$title -> $image to $to');
            if (title.isNotEmpty) {
              return await emailSender.send(to, title, image);
            }
          } else {
            print('$title -> no image found');
          }
        }
      }
    }

    return false;
  }
}
