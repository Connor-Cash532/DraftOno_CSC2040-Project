import 'package:flutter/material.dart';

// A team in the draft: a unique name and the color used for its column.
class Team {
  final String name;
  final Color color;

  const Team({required this.name, required this.color});
}

// One distinct color per team slot (team 1 = red, team 2 = blue, ...).
// Five colors because the draft supports up to five teams.
const List<Color> teamColors = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.purple,
  Colors.orange,
];
