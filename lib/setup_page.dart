import 'package:flutter/material.dart';

import 'main.dart';
import 'team.dart';

// First screen of the app: choose 3-5 teams and name them before the draft.
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  static const int maxTeams = 5;

  int numTeams = 3;
  String? errorMessage;

  // One text box controller per possible team. We keep all five so names
  // aren't lost if the user switches from 5 teams to 3 and back.
  final List<TextEditingController> nameControllers = List.generate(
    maxTeams,
    (i) => TextEditingController(text: 'Team ${i + 1}'),
  );

  @override
  void dispose() {
    for (final controller in nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Returns an error message, or null if every name is filled in and unique.
  String? validateNames() {
    final seen = <String>{};
    for (int i = 0; i < numTeams; i++) {
      final name = nameControllers[i].text.trim();
      if (name.isEmpty) {
        return 'Enter a name for team ${i + 1}.';
      }
      // Compare lowercase so "Bulls" and "bulls" count as the same name.
      if (!seen.add(name.toLowerCase())) {
        return 'Each team needs a different name. "$name" is used twice.';
      }
    }
    return null;
  }

  void startDraft() {
    final error = validateNames();
    if (error != null) {
      setState(() => errorMessage = error);
      return;
    }

    final teams = [
      for (int i = 0; i < numTeams; i++)
        Team(name: nameControllers[i].text.trim(), color: teamColors[i]),
    ];

    // pushReplacement removes the setup page, so the user can't go back
    // and change the teams once the draft has started.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DraftPage(teams: teams)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draft setup')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Number of teams', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 4, label: Text('4')),
                  ButtonSegment(value: 5, label: Text('5')),
                ],
                selected: {numTeams},
                onSelectionChanged: (selection) {
                  setState(() {
                    numTeams = selection.first;
                    errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text('Team names', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              // Only show as many name boxes as there are teams.
              for (int i = 0; i < numTeams; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: nameControllers[i],
                    onChanged: (_) => setState(() => errorMessage = null),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Team ${i + 1}',
                      // Colored dot shows which color this team gets.
                      prefixIcon: Icon(Icons.circle, color: teamColors[i]),
                    ),
                  ),
                ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ElevatedButton(
                onPressed: startDraft,
                child: const Text('Start draft'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
