import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:get_comics/fetch_comic.dart';
import 'package:get_comics/get_comics.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addOption('config', abbr: 'c');
  var results = parser.parse(arguments);

  if (results['config'] != null) {
    final yaml = loadYamlDocument(io.File(results['config']).readAsStringSync());
    final config = yaml.contents.value['config'];
    final comics = yaml.contents.value['comics'];

    if (!await getComics(FetchComic(), config, comics)) {
      io.exit(-1);
    }
  }
}
