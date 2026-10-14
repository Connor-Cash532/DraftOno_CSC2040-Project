import 'dart:collection';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

import 'package:excel_plus/excel_plus.dart' hide Border; // hide excel's Border so Flutter's Border is used in the grid

import 'setup_page.dart';
import 'team.dart';

Future <HashMap<String, String>> readExcel() async { // Function reads the file Master.xlsx in the assets folder
  WidgetsFlutterBinding.ensureInitialized();

  final data = await rootBundle.load('assets/Master.xlsx');
  final excel = Excel.decodeBytes(data.buffer.asUint8List());
  HashMap<String, String> ids = HashMap();
  String id;
  String name;
  for (final row in excel.streamRowsAsMaps('Master')) {
    print(row['ID']);
    ids[row['ID'].toString()] = row['Player'];
  }
  return ids; //Function returns a hashmap with the ID as the key and player name as the value
}

late final HashMap<String, String> ids;


Future<void> main() async{
  ids = await readExcel();
  runApp(const MainDraftPage());

}

class MainDraftPage extends StatelessWidget {
  const MainDraftPage({super.key});

  @override
  Widget build(BuildContext context) {
    // The app now opens on the setup page; it navigates to DraftPage
    // once the teams are chosen.
    return const MaterialApp(home: SetupPage());
  }
}

class DraftPage extends StatefulWidget {
  const DraftPage({super.key, required this.teams});

  final List<Team> teams; // teams chosen on the setup page (3 to 5)

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  static const int rounds = 10;

  late int numTeams;   // number of columns in the grid
  late int totalPicks; // numTeams * rounds

  String checkID(String id){
    if(ids.containsKey(id)){
      return ids[id] ?? 'Temp';
    }
    return "Temp";
  }

  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    numTeams = widget.teams.length;
    totalPicks = numTeams * rounds;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final idCotroller = TextEditingController();
  String tempId = "";
  var id = <String>["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""];
  int ind = 0;
  String player = "";
  Widget buildTextField() =>  TextField( // widget for a text input box that saves the id and checks if it is valid.
            onChanged: (value) { // saves the content of the box
              tempId = value;
              print(tempId);
            },
            //onSubmitted: (value) => print(value),
            onSubmitted: (value) { // if the entered value is an id and there are still available picks then it changes the state of the gridB widget
              tempId = value;
              player = checkID(tempId);
              print(tempId);
              print(ind);
              if(ind < totalPicks && player != 'Temp'){
                id[ind] = player;
                ind++;
                setState(() {
                  gridB(context);
                });
              }
              print(id);
              idCotroller.clear();
            },
            controller: idCotroller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'ID',

              suffixIcon: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => idCotroller.clear(),
              )
            ),
          );

  // Row of team names that sits directly above the grid, one per column.
  Widget teamHeaders() => Row(
    children: [
      for (final team in widget.teams)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: team.color,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                team.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget gridB(BuildContext context) => GridView.builder( //Grid Wdige
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: numTeams, // one column per team
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                // lowered from 0.085 to leave room for the team name row
                mainAxisExtent: MediaQuery.of(context).size.height * 0.075,
              ),
    itemCount: totalPicks, //# of teams times 10
    shrinkWrap: true, //causes the grid to be not scrollable if it does not fit in the screen size
    itemBuilder: (context, index) {
          // index % numTeams is the column, which is the team making this pick
          final team = widget.teams[index % numTeams];
          final isPicked = index < ind;
          final isCurrentPick = index == ind;
          return Padding( //Padding widget that adds padding between the grid boxes
            padding: const EdgeInsets.all(2.0),
            child: Container( // grid item
              decoration: BoxDecoration(
                // made picks are the full team color; upcoming picks are a faded version
                color: isPicked ? team.color : team.color.withValues(alpha: 0.25),
                // thick border marks the pick currently on the clock
                border: isCurrentPick ? Border.all(color: Colors.black, width: 3) : null,
                borderRadius: BorderRadius.circular(10.0), // rounds the edges for the grid item
              ),
              child: Center( // grid item contnet
                child: Text("Pick: " + id[index],
                  style: TextStyle(
                    color: isPicked ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        },
      );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
        Container(
          color: Colors.yellow,
          child: Column( // Column is a widget that takes in children and places widgets vertically
            children: [
              Padding(padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    teamHeaders(),
                    gridB(context),
                  ],
                ),
              ),
              Row(children: [ // Row is a widget that takes in children and places widgets horizontally
                Padding(padding: EdgeInsets.all(5.0),),
                  Expanded( // expanded causes the child widgets to take up all available horizontal space
                    child: buildTextField()
                  ),
                ],
              )
            ],
        )
        ),
    );
  }
}
