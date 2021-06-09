import 'dart:io' as io;

import 'package:dcli/dcli.dart';
import 'package:get_comics/get_comics.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addOption('config', abbr: 'c');
  var results = parser.parse(arguments);

  if (results['config'] != null) {
    final yaml = loadYaml(io.File(results['config']).readAsStringSync());
    final config = yaml['config'];
    final comics = yaml['comics'];

    if (!await getComics(config, comics)) {
      io.exit(-1);
    }
    ;
  }
}
