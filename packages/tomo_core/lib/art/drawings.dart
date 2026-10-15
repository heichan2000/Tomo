// Every drawing Tomo ships, with the canonical text its fingerprint is taken
// over (the rule is in pixel_art.dart's library doc). The art test hashes each
// text and holds it to the drawing's mark (spec §9.6).

import '../pet/species.dart';
import 'icons.dart';
import 'pets/geode.dart';
import 'pets/joe.dart';
import 'pets/lily.dart';
import 'pixel_art.dart';
import 'sparkle.dart';
import 'tomo_egg.dart';

/// The three starters, in the order they are offered.
const List<SpeciesArt> allSpecies = [geode, joe, lily];

/// The art of [species].
SpeciesArt artOf(Species species) => switch (species) {
  Species.geode => geode,
  Species.joe => joe,
  Species.lily => lily,
};

/// One drawing: its id, its mark, and the canonical text its fingerprint is
/// taken over.
final class Drawing {
  const Drawing(this.id, this.mark, this.text);

  final String id;
  final Mark mark;
  final List<String> text;
}

/// Every drawing, pets first, then the icons in [IconName] order, the sparkle
/// and the Tomo egg. An icon missing from [icons] is left out; the art test
/// checks for that separately.
List<Drawing> allDrawings() => [
  for (final species in allSpecies) ...speciesDrawings(species),
  for (final name in IconName.values)
    if (icons[name] case final icon?)
      Drawing('icon.${name.name}', icon.mark, iconText(name, icon)),
  Drawing('sparkle', sparkle.mark, sparkleText(sparkle)),
  Drawing('tomo.egg', tomoEgg.mark, tomoEggText(tomoEgg)),
];

/// A species' egg, its stages and its eye sheet.
List<Drawing> speciesDrawings(SpeciesArt species) {
  final id = species.name.toLowerCase();
  return [
    Drawing('$id.egg', species.egg.mark, eggText(species)),
    for (var i = 0; i < species.stages.length; i++)
      Drawing(
        '$id.stage${i + 1}',
        species.stages[i].mark,
        stageText(species, i),
      ),
    Drawing('$id.eyes', species.eyeSheet.mark, eyesText(species)),
  ];
}

List<String> stageText(SpeciesArt species, int index) {
  final id = species.name.toLowerCase();
  final stage = species.stages[index];
  final grids = [for (final part in Part.values) gridRows(stage.parts[part]!)];
  String parts(Iterable<Part> ps) =>
      ps.isEmpty ? '-' : ps.map((p) => p.name).join(' ');
  String inOrder(Set<Part> ps) => parts(Part.values.where(ps.contains));
  return [
    'tomo-art 1',
    'drawing $id.stage${index + 1}',
    ..._colourLines(species.colours, grids),
    'order ${parts(species.paintOrder)}',
    'rides ${inOrder(species.ridesWithHead)}',
    'leans-whole ${inOrder(species.leansWhole)}',
    'twitches ${inOrder(species.twitches)}',
    'lifts-on-jump ${inOrder(species.liftsOnJump)}',
    for (final eye in stage.eyes) 'eye ${eye.x} ${eye.y}',
    'lean ${stage.leanStep}',
    'breath ${stage.breathRow ?? '-'}',
    for (final (k, part) in Part.values.indexed) ...[
      'grid ${part.name}',
      ...grids[k],
    ],
  ];
}

List<String> eggText(SpeciesArt species) {
  final egg = species.egg;
  final grids = [gridRows(egg.whole), ...egg.cracks.map(gridRows)];
  final stays = egg.staysAtHatch.toList()..sort();
  return [
    'tomo-art 1',
    'drawing ${species.name.toLowerCase()}.egg',
    ..._colourLines(species.colours, grids),
    'stays ${stays.isEmpty ? '-' : stays.join()}',
    'grid whole',
    ...grids.first,
    for (var k = 1; k < grids.length; k++) ...['grid crack$k', ...grids[k]],
  ];
}

List<String> eyesText(SpeciesArt species) {
  final faces = species.eyeSheet.faces;
  final grids = [
    for (final shape in EyeShape.values) gridRows(faces[shape]!.grid),
  ];
  return [
    'tomo-art 1',
    'drawing ${species.name.toLowerCase()}.eyes',
    ..._colourLines(species.colours, grids),
    for (final (k, shape) in EyeShape.values.indexed) ...[
      'grid ${shape.name} ${faces[shape]!.offset.x} ${faces[shape]!.offset.y}',
      ...grids[k],
    ],
  ];
}

List<String> iconText(IconName name, IconArt icon) {
  final rows = gridRows(icon.grid);
  return [
    'tomo-art 1',
    'drawing icon.${name.name}',
    ..._paintLines(IconArt.paints, [rows]),
    'grid icon',
    ...rows,
  ];
}

List<String> sparkleText(Sparkle sparkle) {
  final grids = sparkle.frames.map(gridRows).toList();
  return [
    'tomo-art 1',
    'drawing sparkle',
    ..._paintLines(Sparkle.paints, grids),
    for (final (k, rows) in grids.indexed) ...['grid frame${k + 1}', ...rows],
  ];
}

List<String> tomoEggText(TomoEgg egg) {
  final rows = gridRows(egg.grid);
  return [
    'tomo-art 1',
    'drawing tomo.egg',
    ..._colourLines(egg.colours, [rows]),
    'grid whole',
    ...rows,
  ];
}

/// The characters other than `.` that [grids] use, sorted by character code.
List<String> _used(List<List<String>> grids) {
  final used = <String>{
    for (final rows in grids)
      for (final row in rows)
        for (final c in row.split(''))
          if (c != '.') c,
  };
  return used.toList()..sort();
}

List<String> _colourLines(Map<String, int> key, List<List<String>> grids) => [
  for (final c in _used(grids))
    'colour $c #${((key[c] ?? 0) & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
];

List<String> _paintLines(
  Map<String, String> paints,
  List<List<String>> grids,
) => [for (final c in _used(grids)) 'paint $c ${paints[c] ?? '?'}'];
