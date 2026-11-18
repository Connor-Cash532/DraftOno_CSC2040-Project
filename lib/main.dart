import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

import 'package:excel_plus/excel_plus.dart' hide Border;
import 'sophia_features.dart';
import 'setup_page.dart';
import 'team.dart';
 
Future <List<HashMap<String, dynamic>>> readExcel() async { // Function reads the file Master.xlsx in the assets folder
  WidgetsFlutterBinding.ensureInitialized();

  final data = await rootBundle.load('assets/Master.xlsx');
  List<HashMap<String, dynamic>> idAndSalaryList = [];
  final excel = Excel.decodeBytes(data.buffer.asUint8List());
  HashMap<String, String> ids = HashMap();
  HashMap<String, int> salary = HashMap();

  for (final row in excel.streamRowsAsMaps('Master')) { 
    ids[row['ID'].toString()] = row['Player'];
    if(row['Salary'] is int){
      salary[row['ID'].toString()] = row['Salary'];
    } else{
        salary[row['ID'].toString()] = 999999999999; 
    }

    final id = row['ID'].toString();

    double stat(String column) =>
        double.tryParse(row[column].toString()) ?? 0;

    final games = stat('G');
    final points = games > 0 ? stat('PTS') / games : 0;
    final rebounds = games > 0 ? stat('TRB') / games : 0;
    final assists = games > 0 ? stat('AST') / games : 0;

    final score = points + rebounds * 1.2 + assists * 1.5;

    if (score >= 30) {
      playerGrades[id] = 'A';
    } else if (score >= 23) {
      playerGrades[id] = 'B';
    } else if (score >= 16) {
      playerGrades[id] = 'C';
    } else if (score >= 9) {
      playerGrades[id] = 'D';
    } else {
      playerGrades[id] = 'F';
    }
  }
  idAndSalaryList.add(ids);
  idAndSalaryList.add(salary);
  return idAndSalaryList; //Function returns a hashmap with the ID as the key and player name as the value
}

late final HashMap<String, String> ids;
late final HashMap<String, int> salary;
final Map<String, String> playerGrades = {};


Future<void> main() async{
  List<HashMap<String, dynamic>> idAndSalaryList = await readExcel();
  ids = (idAndSalaryList)[0] as HashMap<String, String>;
  salary = (idAndSalaryList)[1] as HashMap<String, int>;

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
  const DraftPage({
    super.key,
    required this.teams,
    this.maxSeconds = 120,
    this.salaryCap = 110,
  });

  final List<Team> teams; // teams chosen on the setup page (3 to 5)
  final int maxSeconds;   // pick timer length chosen on the setup page
  final int salaryCap;    // salary cap chosen on the setup page (in millions)

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  static const int rounds = 10;

  late int numTeams;   // number of columns in the grid
  late int totalPicks; // numTeams * rounds
  late double maxSalary;

  String checkIDPlayer(String id){
    if(ids.containsKey(id)){
      return ids[id] ?? 'Temp';
    }
    return "Temp";
  }

  int checkIDSalary(String id){
    if(salary.containsKey(id)){
      return salary[id] ?? 0;
    }
    return -1;
  }

  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    numTeams = widget.teams.length;
    totalPicks = numTeams * rounds;
    maxSalary = widget.salaryCap.toDouble() * pow(10,6).toDouble();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final idCotroller = TextEditingController();
  String tempId = "";
  List playerNames = <String>["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""];
  int ind = 0;
  Map<int, String> playerRatings = {}; // stores automatic letter grades
  List<String> draftedIds = []; // tracks IDs so undo removes the correct player
  HashMap<String, String> chosenPlayers = HashMap<String, String>();
  List<double> teamSalarySpace = List<double>.filled(5, 0);

  String player = "";
  int playerSalary = 0;
  int teamNum = 0;

  Widget buildTextField() =>  TextField( // widget for a text input box that saves the id and checks if it is valid.
            onChanged: (value) { // saves the content of the box
              tempId = value;
              //print(tempId);
            },
            //onSubmitted: (value) => print(value),
            onSubmitted: (value) { // if the entered value is an id and there are still available picks then it changes the state of the gridB widget
              tempId = value;
              player = checkIDPlayer(tempId);
              playerSalary = checkIDSalary(tempId);
              teamNum = ind % numTeams;
              //print(tempId);
              //print(ind);
              print(playerSalary);
              print(teamSalarySpace);
              if(ind < totalPicks && player != 'Temp' && !chosenPlayers.containsKey(tempId) && teamSalarySpace[teamNum] + playerSalary <= maxSalary){
                print(teamNum);
                chosenPlayers[tempId] = player; 
                playerRatings[ind] = playerGrades[tempId] ?? 'F';
                playerNames[ind] = player;
                teamSalarySpace[teamNum] = teamSalarySpace[teamNum] + playerSalary;
                ind++;
                draftedIds.add(tempId);
                setState(() {
                  gridB(context);
                });
                _resetTimer();
                _startTimer();
              }
              else if (player == 'Temp') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid Player ID. Please enter a valid ID.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              else if (chosenPlayers.containsKey(tempId)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('This player has already been drafted!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              print(playerNames);
              idCotroller.clear();
            },
            key: Key('idTextField'),
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

  Widget gridB(BuildContext context) => GridView.builder( //Grid Widget
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: numTeams,
      crossAxisSpacing: 0,
      mainAxisSpacing: 0,
      mainAxisExtent: MediaQuery.of(context).size.height * 0.65 / rounds,
    ),
    // lowered from 0.085 to leave room for the team name row

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pick: " + playerNames[index],
                      key: Key("Grid $index"),
                      style: TextStyle(
                        color: isPicked ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (isPicked)
                      Text(
                        'Grade: ${playerRatings[index] ?? "N/A"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  void _startTimer(){
      tim?.cancel();
      tim = Timer.periodic(Duration(seconds: 1), (timer) {
        if(timeLeft > 0){
          setState(() {
            timeLeft--;
          });
        }
        else{
          timer.cancel();
        }
      });

  }

  void _resetTimer(){
    tim?.cancel();
    setState(() {
      timeLeft = MAX_SECONDS;
    });
  }

  late int timeLeft = MAX_SECONDS; // late so it can read MAX_SECONDS from the widget
  int get MAX_SECONDS => widget.maxSeconds; // set on the setup page (was a constant 120)
  Timer? tim;
  Widget timerB(BuildContext context){    
    return Container(
      //height: MediaQuery.of(context).size.height * 0.15,
      decoration: BoxDecoration(
        color: Colors.blue, 
        borderRadius: BorderRadius.circular(20.0), 
      ),
      child: Column(
        children: [
            Text(
              style: TextStyle( fontSize: MediaQuery.of(context).size.height * 0.05),
              timeLeft.toString(),
            ),
          Row(
            children: [
              Padding(padding: EdgeInsets.all(5.0),),
              TextButton(
                onPressed: () {
                  _startTimer();
                },
                style: ButtonStyle( // Make pick that when pressed submits the ID entered in the text box to be the team pick
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                  backgroundColor: WidgetStateProperty.all<Color>(Colors.red)
                ),
                child: Text("Start"),
              ),
              Padding(padding: EdgeInsets.all(5.0),),
              TextButton(
                onPressed: () {
                  _resetTimer();
                },
                style: ButtonStyle( // Make pick that when pressed submits the ID entered in the text box to be the team pick
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                  backgroundColor: WidgetStateProperty.all<Color>(Colors.red)
                ),
                child: Text("Reset"),
              ),
              Padding(padding: EdgeInsets.all(5.0),),
              TextButton(
                onPressed: () {
                  tim?.cancel();
                },
                style: ButtonStyle( // Make pick that when pressed submits the ID entered in the text box to be the team pick
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                  backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                ),
                child: Text("Pause"),
              ),
              Padding(padding: EdgeInsets.all(5.0),),
            ],
          ),
          Padding(padding: EdgeInsets.all(5.0),),
        ],
      ),
    );
    
  }

    
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
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: gridB(context),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(children: [ // Row is a widget that takes in children and places widgets horizontally
                  Padding(padding: EdgeInsets.all(5.0),),
                    Expanded( // expanded causes the child widgets to take up all available horizontal space
                      child: buildTextField()
                    ),
                  Padding(padding: EdgeInsets.all(5.0),),
                    TextButton(
                      key: Key('SubmitPickButton'),
                      style: ButtonStyle( // Make pick that when pressed submits the ID entered in the text box to be the team pick
                        foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                        backgroundColor: WidgetStateProperty.all<Color>(Colors.red)
                      ),
                      onPressed: (){ 
                        player = checkIDPlayer(tempId);
                        playerSalary = checkIDSalary(tempId);
                        teamNum = ind % numTeams;
                        print(maxSalary);
                        if(ind < 50 && player != 'Temp' && !chosenPlayers.containsKey(tempId) && playerSalary + teamSalarySpace[teamNum] <= maxSalary){
                          teamSalarySpace[teamNum] = teamSalarySpace[teamNum] + playerSalary;
                          playerNames[ind] = player;
                          chosenPlayers[tempId] = player;
                          draftedIds.add(tempId);
                          playerRatings[ind] = playerGrades[tempId] ?? 'F';
                          ind++;
                          setState(() {
                            gridB(context);
                          });
                          _resetTimer();
                          _startTimer();
                        }
                        idCotroller.clear();
                      }, 
                      child: Text("Make Pick")
                    ),
                    Padding(padding: EdgeInsets.all(5.0),),
                    TextButton(
                      key: Key('UndoPickButton'),
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                        backgroundColor: WidgetStateProperty.all<Color>(Colors.red)
                      ),
                      onPressed: (){
                        if(ind > 0){
                          ind--;
                          String lastId = draftedIds.removeLast();
                          teamNum = ind % numTeams;
                          teamSalarySpace[teamNum] = teamSalarySpace[teamNum] - checkIDSalary(lastId);
                          playerNames[ind] = '';
                          chosenPlayers.remove(lastId);
                          playerRatings.remove(ind);
                          setState(() {
                            gridB(context);
                          });
                          _resetTimer();
                          _startTimer();
                        }
                      }, 
                      child: Text("Undo Pick")
                    ),
                    Padding(padding: EdgeInsets.all(5.0),),
                                      timerB(context)
                                    ],
                                  ),
              ),
                              ],
                            ),
                          ),
                      );
                    }
                  }