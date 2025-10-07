import 'package:clock/clock.dart';
import 'package:puppeteer/puppeteer.dart';
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

  Future<String> getComicContentWithPuppeteer(String url) async {
    print('url $url');
    Browser? browser;
    try {
      browser = await puppeteer.launch(
        headless: true,
        executablePath: '/usr/bin/chromium',
        args: [
          '--no-sandbox',
          '--disable-blink-features=AutomationControlled',
        ],
      );
      var page = await browser.newPage();
      await page.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      );
      await page.setViewport(DeviceViewport(width: 1280, height: 800));
      var watchTitle = page.waitForSelector('meta[property="og:title"]');
      await page.goto(url, wait: Until.networkIdle);
      await watchTitle;
      final content = await page.content;
      return content!;
    } catch (e) {
      print('Puppeteer error: $e');
      return '';
    } finally {
      await browser?.close();
    }
  }

  Future<bool> fetchComic(
    String comicUrl,
    List<String> to,
    dynamic dio, // Not used anymore, kept for compatibility
    EmailSender emailSender,
    String? dateSepChar,
  ) async {
    final url = makeComicUrl(comicUrl, dateSepChar);
    if (url == null) {
      return false;
    }

    final contents = await getComicContentWithPuppeteer(url);
    if (contents.isEmpty) {
      print('Failed to fetch content, ignoring');
      return false;
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
    if (ogTitle == null || ogImage == null || ogTitle.isEmpty || ogImage.isEmpty) {
      print('Failed to extract og:title or og:image');
      return false;
    }
    return await emailSender.send(to, ogTitle, ogImage);
  }
}
