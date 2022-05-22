import 'package:get_comics/fetch_comic.dart';
import 'package:test/test.dart';
import 'package:clock/clock.dart';

import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:dio/dio.dart';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_comics/email_sender.dart';
import 'fetch_comic_test.mocks.dart';
// class MockEmailSender extends Mock implements EmailSender {}

@GenerateMocks([EmailSender])
void main() {
  late DioAdapter dioAdapter;
  late Dio dio;
  setUpAll(() {
    dioAdapter = DioAdapter(dio: Dio());
    dio = Dio()..httpClientAdapter = dioAdapter;
  });

  test('makeComicUrl', () {
    withClock(Clock.fixed(DateTime(2021, 05, 12)), () {
      final fetchComic = FetchComic();
      expect(fetchComic.makeComicUrl('https://www.comics.com/fuzzy', null), 'https://www.comics.com/fuzzy/2021/05/11');
      expect(fetchComic.makeComicUrl('https://www.comics.com/fuzzy?parameter=something', null), 'https://www.comics.com/fuzzy/2021/05/11?parameter=something');

      expect(fetchComic.makeComicUrl('https://www.comics.com/fuzzy', '-'), 'https://www.comics.com/fuzzy/2021-05-11');

      expect(fetchComic.makeComicUrl('https://www.comics.com/fuzzy?parameter=something', '-'), 'https://www.comics.com/fuzzy/2021-05-11?parameter=something');
    });
  });

  test('getComicContent', () async {
    dioAdapter.onGet(
      'https://www.comics.com/fuzzy/2021/05/10',
      (request) => request.reply(200, '<html><title>A Comic</title><meta name="twitter:image" content="http://some.comic.image/12345"'),
    );
    final fetchComic = FetchComic();
    expect(await fetchComic.getComicContent(dio, 'https://www.comics.com/fuzzy/2021/05/10'), '<html><title>A Comic</title><meta name="twitter:image" content="http://some.comic.image/12345"');
  });

  test('fetchComic', () async {
    await withClock(Clock.fixed(DateTime(2021, 05, 12)), () async {
      dioAdapter.onGet(
        'https://www.comics.com/fuzzy/2021/05/11',
        (request) => request.reply(200, '<html><title>A Comic</title><meta name="twitter:image" content="http://some.comic.image/12345"/>'),
      );
      final emailSender = MockEmailSender();
      when(emailSender.send(['test@email'], 'A Comic', 'http://some.comic.image/12345')).thenAnswer((_) => Future.value(true));

      final fetchComic = FetchComic();
      final value = await fetchComic.fetchComic('https://www.comics.com/fuzzy', ['test@email'], dio, emailSender, null);
      expect(value, true);

      verify(emailSender.send(['test@email'], 'A Comic', 'http://some.comic.image/12345')).called(1);
    });
  });

  test('fails to decode url', () {
    final fetchComic = FetchComic();
    expect(fetchComic.makeComicUrl('s%41://x.x/', null), isNull);
  });

  test('fetchComicNoFindComic', () async {
    await withClock(Clock.fixed(DateTime(2021, 05, 12)), () async {
      dioAdapter.onGet(
        'https://www.comics.com/fuzzy/2021/05/11',
        (request) => request.reply(200, '<html><title>A Comic</title><meta name="twitter:imagine" content="http://some.comic.image/12345"/>'),
      );
      final emailSender = MockEmailSender();

      final fetchComic = FetchComic();
      final value = await fetchComic.fetchComic('https://www.comics.com/fuzzy', ['test@email'], dio, emailSender, null);
      expect(value, false);

      verifyZeroInteractions(emailSender);
    });
  });

  test('fetchComicBadURL', () async {
    await withClock(Clock.fixed(DateTime(2021, 05, 11)), () async {
      final emailSender = MockEmailSender();
      final fetchComic = FetchComic();
      final value = await fetchComic.fetchComic('s%41://x.x/', ['test@email'], dio, emailSender, null);
      expect(value, false);

      verifyZeroInteractions(emailSender);
    });
  });
}
