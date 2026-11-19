import 'dart:collection';
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
    playerSalaries[id] =  // reads the players salary
        int.tryParse(row['Salary'].toString()) ?? 0;

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
final Map<String, int> playerSalaries = {}; // player's salary in dollars.


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
  late List<int> pickOwners; // current owner of each pick
  late List<double> teamBudgets;  // each teams remaining money (millions)
  final List<TradeRecord> tradeHistory = []; // stores completed trades
  final List<String> actionHistory = []; // order of trades and selections

  // trades  current pick for a later pick + money
  bool tradePicks(int laterPickIndex, int money) {
    // Prevent trades after the draft is finished.
    if (ind >= totalPicks) return false;

    // only allow trades for picks that haven't happened yet
    if (laterPickIndex <= ind || laterPickIndex >= totalPicks) {
      return false;
    }

    // find current owners of both picks
    final currentTeam = pickOwners[ind];
    final otherTeam = pickOwners[laterPickIndex];

    // teams cant trade with themselves
    if (currentTeam == otherTeam) return false;

    // teams can only trade money they have
    if (money <= 0 || money > teamBudgets[otherTeam]) {
      return false;
    }

    setState(() {
      // exchnage ownership of the two picks
      pickOwners[ind] = otherTeam;
      pickOwners[laterPickIndex] = currentTeam;

      // transfer money between teams.
      teamBudgets[otherTeam] -= money;
      teamBudgets[currentTeam] += money;
    });

    // saves the completed trade
    tradeHistory.add(
      TradeRecord(
        currentPickIndex: ind,
        laterPickIndex: laterPickIndex,
        currentTeam: currentTeam,
        otherTeam: otherTeam,
        money: money,
      ),
    );
    actionHistory.add('trade');  // records action was a trade

    _resetTimer(); // reset the timer trade
    _startTimer();

    return true;
  }

  // reverse trade
  void undoTrade() {

    // stops if there are no trades to undo
    if (tradeHistory.isEmpty) return;

    // most recent trade
    final trade = tradeHistory.removeLast();

    setState(() {

      // gives both picks back to their previous owners
      pickOwners[trade.currentPickIndex] = trade.currentTeam;
      pickOwners[trade.laterPickIndex] = trade.otherTeam;

      // return to its previous owners
      teamBudgets[trade.currentTeam] -= trade.money;
      teamBudgets[trade.otherTeam] += trade.money;
    });

    _resetTimer();
    _startTimer();
  }

  // trading pick and money
  Future<void> showTradeDialog() async {
    final pickController = TextEditingController();
    final moneyController = TextEditingController();

    // pause draft timer
    tim?.cancel();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Trade Pick'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Pick: ${ind + 1}'),

              // enter the later pick to trade for
              TextField(
                controller: pickController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Later Pick Number',
                ),
              ),

              // enter the money in the trade
              TextField(
                controller: moneyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Money (in millions)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final pickNumber = int.tryParse(pickController.text);
                final money = int.tryParse(moneyController.text);
                if (pickNumber == null || money == null) return;
                // converts the pick number to index
                final success = tradePicks(pickNumber - 1, money);
                // closes the popup when the trade succeeds
                if (success) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Confirm Trade'),
            ),
          ],
        );
      },
    );

    // restarts the timer only if it isn't already running
    if (mounted && (tim == null || !tim!.isActive)) {
      _startTimer();
    }

    pickController.dispose();
    moneyController.dispose();
  }

  // snake draft order
  int teamIndexForPick(int pickIndex) {
    final round = pickIndex ~/ numTeams;
    final position = pickIndex % numTeams;

    if (round.isEven) {
      return position;
    } else {
      return numTeams - 1 - position;
    }
  }
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

    // initialize snake draft pick ownership
    pickOwners = List.generate(
      totalPicks,
          (index) => teamIndexForPick(index),
    );

    // initialize each teams remaining budget
    teamBudgets = List.filled(
      numTeams,
      widget.salaryCap.toDouble(),
    );

    // convert salary cap from millions to dollars
    maxSalary = widget.salaryCap * 1000000.0;
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
  Map<int, String> playerIds = {}; // player ID
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
    onSubmitted: (value) {
      tempId = value;
      player = checkIDPlayer(tempId);
      playerSalary = checkIDSalary(tempId);

      if (ind < totalPicks &&
          player != 'Temp' &&
          !chosenPlayers.containsKey(tempId)) {

        // use the actual owner of the pick
        teamNum = pickOwners[ind];

        // check that the player fits under the salary cap
        if (playerSalary < 0 ||
            playerSalary / 1000000.0 > teamBudgets[teamNum]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough salary cap space for this player.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          setState(() {
            chosenPlayers[tempId] = player;
            playerNames[ind] = player;
            playerIds[ind] = tempId;
            playerRatings[ind] = playerGrades[tempId] ?? 'F';
            draftedIds.add(tempId);
            teamSalarySpace[teamNum] += playerSalary;
            teamBudgets[teamNum] -= playerSalary / 1000000.0;
            actionHistory.add('pick');
            ind++;
          });

          _resetTimer();
          _startTimer();
        }
      } else if (player == 'Temp') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Player ID. Please enter a valid ID.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (chosenPlayers.containsKey(tempId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This player has already been drafted!'),
            backgroundColor: Colors.red,
          ),
        );
      }

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

  // displays team's name and remaining salary cap
  Widget teamHeaders() => Row(
    children: [
      for (int i = 0; i < widget.teams.length; i++)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: widget.teams[i].color,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  // team name
                  Text(
                    widget.teams[i].name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // remaining salary cap
                  Text(
                    '\$${teamBudgets[i].toStringAsFixed(2)}M remaining',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
      // teams in fixed columns
      final column = index % numTeams;
      final round = index ~/ numTeams;

      // snake draft order
      final pickIndex = round * numTeams +
          (round.isEven ? column : numTeams - 1 - column);

      final team = widget.teams[pickOwners[pickIndex]]; // team that currently owns the pick
      final isPicked = pickIndex < ind;
      final isCurrentPick = pickIndex == ind;
          return Padding( //Padding widget that adds padding between the grid boxes
            padding: const EdgeInsets.all(2.0),
            child: Container( // grid item
              decoration: BoxDecoration(
                color: isPicked
                    ? Color.lerp(team.color, Colors.white, 0.15)!
                    : Color.lerp(team.color, Colors.white, 0.78)!,
                // thick border marks the pick currently on the clock
                border: isCurrentPick
                    ? Border.all(color: const Color(0xFF344054), width: 2.5)
                    : null,
                borderRadius: BorderRadius.circular(10.0), // rounds the edges for the grid item
              ),
              child: Center( // grid item contnet
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pick: " + playerNames[pickIndex],
                      key: Key("Grid $index"),
                      style: TextStyle(
                        color: isPicked ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Display the player's ID under their name.
                    if (isPicked)
                      Text(
                        playerIds[pickIndex] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    if (isPicked)
                      Text(
                        'Grade: ${playerRatings[pickIndex] ?? "N/A"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
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
      child:
      Column(
        children: [
            Text(
              style: TextStyle( fontSize: MediaQuery.of(context).size.height * 0.05),
              timeLeft.toString(),
            ),
          SizedBox(
            child: Row(
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
          color: const Color(0xFFF5F6FA),
          child:
          Column( // Column is a widget that takes in children and places widgets vertically
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
                    key: const Key('SubmitPickButton'),
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                      backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                    ),
                    onPressed: () {
                      player = checkIDPlayer(tempId);
                      playerSalary = checkIDSalary(tempId);

                      if (ind < totalPicks &&
                          player != 'Temp' &&
                          !chosenPlayers.containsKey(tempId)) {

                        // get the actual team that owns the pick
                        teamNum = pickOwners[ind];

                        // check the team's remaining salary budget
                        if (playerSalary < 0 ||
                            playerSalary / 1000000.0 > teamBudgets[teamNum]) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Not enough salary cap space for this player.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          setState(() {
                            playerNames[ind] = player;
                            playerIds[ind] = tempId;
                            playerRatings[ind] = playerGrades[tempId] ?? 'F';
                            chosenPlayers[tempId] = player;
                            draftedIds.add(tempId);

                            teamSalarySpace[teamNum] += playerSalary;
                            teamBudgets[teamNum] -= playerSalary / 1000000.0;

                            actionHistory.add('pick');
                            ind++;
                          });

                          _resetTimer();
                          _startTimer();
                        }
                      }

                      idCotroller.clear();
                    },
                    child: const Text('Make Pick'),
                  ),

                  const SizedBox(width: 5),

                TextButton(
                  key: const Key('UndoPickButton'),
                  onPressed: () {
                    if (actionHistory.isEmpty) return;

                    final lastAction = actionHistory.removeLast();

                    if (lastAction == 'trade') {
                      undoTrade();
                    } else if (lastAction == 'pick' && ind > 0) {
                      setState(() {
                        ind--;

                        final lastId = draftedIds.removeLast();
                        final team = pickOwners[ind];
                        final amount = checkIDSalary(lastId);

                        if (amount >= 0) {
                          teamSalarySpace[team] -= amount;
                          teamBudgets[team] += amount / 1000000.0;
                        }

                        playerNames[ind] = '';
                        playerIds.remove(ind);
                        playerRatings.remove(ind);
                        chosenPlayers.remove(lastId);
                      });

                      _resetTimer();
                      _startTimer();
                    }
                  },
                  child: const Text('Undo'),
                ),

                const SizedBox(width: 5),

                TextButton(
                  onPressed: showTradeDialog,
                  child: const Text('Trade'),
                ),

                const SizedBox(width: 5),
                timerB(context),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      );
                    }
                  }

// trade record: used for reversing a trade
class TradeRecord {
  final int currentPickIndex; // current pick being traded right now
  final int laterPickIndex;   // later pick
  final int currentTeam;      // tram originally on the clock
  final int otherTeam;        // tram paying money for the current pick
  final int money;            // amount of money traded

  TradeRecord({
    required this.currentPickIndex,
    required this.laterPickIndex,
    required this.currentTeam,
    required this.otherTeam,
    required this.money,
  });
}