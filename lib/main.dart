import 'dart:collection';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

import 'package:excel_plus/excel_plus.dart';
import 'sophia_features.dart';

 
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
    return const MaterialApp(home: DraftPage());
  }
}

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {

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
              if(ind < 50 && player != 'Temp'){
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

  Widget gridB(BuildContext context) => GridView.builder( //Grid Wdige
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, //5 Teams, for changing to 3 to 5 teams this should be a variable
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                //childAspectRatio: (MediaQuery.of(context).size.width / MediaQuery.of(context).size.height),
                //childAspectRatio: 0.5,
                mainAxisExtent: MediaQuery.of(context).size.height * 0.085,
              ),
    itemCount: 50, //# of teams times 10
    shrinkWrap: true, //causes the grid to be not scrollable if it does not fit in the screen size
    itemBuilder: (context, index) {
          return Padding( //Padding widget that adds padding between the grid boxes
            padding: const EdgeInsets.all(2.0),
            child: Container( // grid item
              decoration: BoxDecoration(
                //color: Colors.green,
                color: index < ind ? Colors.green : index == ind ? Colors.blue : Colors.white, // colors grid based on current pick
                borderRadius: BorderRadius.circular(10.0), // rounds the edges for the grid item
              ),
              child: Center( // grid item contnet
                child: Text("Pick: " + id[index],
                  style: TextStyle(
                    color: Colors.white,
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
    // button to open my draft setup page
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SophiaFeatures(),
          ),
        );
      },
      icon: const Icon(Icons.dashboard),
      label: const Text('Draft Setup'),
    ),

    body:
      Container(
        color: Colors.yellow,
        child: Column( // Column is a widget that takes in children and places widgets vertically
          children: [
            Padding(padding: EdgeInsets.all(16.0),
              child: gridB(context),
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