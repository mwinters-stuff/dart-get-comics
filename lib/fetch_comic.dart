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
    try {
      final response = await dio.get(url);
      return response.data.toString();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return '404';
      }
    }
    return '';
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
    if(contents == '404'){
      print('returned 404, ignoring');
      return true; // pretend it worked.
    }

    final document = parse(contents);

    // Extract og:title and og:image
    final ogTitle = document
        .querySelector('meta[property="og:title"]')
        ?.attributes['content'];
    final ogImage = document
        .querySelector('meta[property="og:image"]')
        ?.attributes['content'];

    print('Name: $ogTitle');
    print('Content URL: $ogImage');
    return await emailSender.send(to, ogTitle!, ogImage!);
  }
}
