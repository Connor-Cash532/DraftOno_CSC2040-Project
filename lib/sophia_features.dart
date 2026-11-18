
import 'package:flutter/material.dart';

// my features for the draft simulator
// includes team setup, salary cap, draft grid, and player ratings

class SophiaFeatures extends StatefulWidget {
  final List<String> players;

  const SophiaFeatures({
    super.key,
    required this.players,
  });

  @override
  State<SophiaFeatures> createState() => _SophiaFeaturesState();
}

class _SophiaFeaturesState extends State<SophiaFeatures> {

  static const int totalRounds = 10; // draft always has 10 rounds

  // colors for the overall app
  static const Color background = Color(0xFF151A24);
  static const Color panel = Color(0xFF222C3C);
  static const Color draftCell = Color(0xFF303D50);

  int teamCount = 5; // starts with 5 teams but can be changed
  double salaryCap = 110; // default salary cap is 110 million

  // default team names
  final List<String> teamNames = [
    'Team 1',
    'Team 2',
    'Team 3',
    'Team 4',
    'Team 5',
  ];

  // starting colors for each team
  final List<Color> teamColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  // colors that users can choose from
  final List<Color> colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  final Map<int, int> playerRatings = {}; // saves ratings for each draft position
  final Map<int, String> draftedPlayers = {}; // will connect to the player IDs later

  int get totalPicks => teamCount * totalRounds; // calculates total number of picks

  int pickNumber(int round, int team) {
    return round * teamCount + team + 1; // figures out the pick number
  }

  int ratingKey(int round, int team) {
    return round * 5 + team; // keeps ratings in the same spot if team count changes
  }

  Widget sectionTitle(String title) { // makes the headings for each section
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildTeamSettings() { // lets users change number of teams, names, and colors
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Team Setup'),
          const Text(
            'Number of Teams',
            style: TextStyle(color: Colors.white70),
          ),
          DropdownButton<int>(
            value: teamCount,
            dropdownColor: panel,
            style: const TextStyle(color: Colors.white),
            items: [3, 4, 5].map((count) {
              return DropdownMenuItem<int>(
                value: count,
                child: Text('$count Teams'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  teamCount = value; // updates how many teams are shown
                });
              }
            },
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < teamCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: teamColors[i],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('team-name-$i'),
                      initialValue: teamNames[i],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Team ${i + 1} Name',
                        labelStyle:
                            const TextStyle(color: Colors.white70),
                        enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.lightBlueAccent),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          teamNames[i] = value; // saves the new team name
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<Color>(
                    value: teamColors[i],
                    dropdownColor: panel,
                    items: colorOptions.map((color) {
                      return DropdownMenuItem<Color>(
                        value: color,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: color,
                        ),
                      );
                    }).toList(),
                    onChanged: (color) {
                      if (color != null) {
                        setState(() {
                          teamColors[i] = color; // changes the team's color
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildSalaryCap() { // slider to choose the salary cap from 10M to 200M
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Salary Cap'),
          Text(
            '\$${salaryCap.round()} Million',
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: salaryCap,
            min: 10,
            max: 200,
            divisions: 190,
            label: '\$${salaryCap.round()}M',
            activeColor: Colors.lightBlueAccent,
            onChanged: (value) {
              setState(() {
                salaryCap = value; // updates salary cap when slider moves
              });
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$10M',
                  style: TextStyle(color: Colors.white70)),
              Text('\$200M',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildDraftBoard() { // creates the grid with 10 rounds and 3-5 teams
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Draft Board'),
          Text(
            '$totalRounds Rounds • $teamCount Teams • $totalPicks Picks',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 75,
                      child: Text(
                        'Round',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    for (int team = 0; team < teamCount; team++)
                      Container(
                        width: 145,
                        height: 50,
                        margin: const EdgeInsets.all(2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: teamColors[team],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          teamNames[team].isEmpty
                              ? 'Team ${team + 1}'
                              : teamNames[team],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                for (int round = 0; round < totalRounds; round++)
                  Row(
                    children: [
                      SizedBox(
                        width: 75,
                        child: Text(
                          'Round ${round + 1}',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      for (int team = 0; team < teamCount; team++)
                        buildDraftPick(round, team),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDraftPick(int round, int team) { // makes one box for each draft pick
    final int pick = pickNumber(round, team);
    final int key = ratingKey(round, team);
    final int? rating = playerRatings[key];

    return Container(
      width: 145,
      height: 105,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: draftCell,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(
            color: teamColors[team],
            width: 3,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pick $pick',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            key < widget.players.length && widget.players[key].isNotEmpty
    ? widget.players[key]
    : 'Available', // player name goes here later
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButton<int>(
            value: rating,
            hint: const Text(
              'Rate',
              style: TextStyle(color: Colors.white70),
            ),
            dropdownColor: panel,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 13,
            ),
            items: [1, 2, 3, 4, 5].map((value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value ★'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                if (value != null) {
                  playerRatings[key] = value; // saves the rating for this pick
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // puts all the sections together on one page
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('DraftOno'),
        backgroundColor: panel,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'NBA Draft Simulator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          buildTeamSettings(),
          const SizedBox(height: 20),
          buildSalaryCap(),
          const SizedBox(height: 20),
          buildDraftBoard(),
        ],
      ),
    );
  }
}
