import 'dart:collection';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

import 'package:excel_plus/excel_plus.dart';
 
Future <HashMap<String, String>> readExcel() async {
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
  return ids;
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
  Widget buildTextField() =>  TextField(
            onChanged: (value) {
              tempId = value;
              print(tempId);
            },
            //onSubmitted: (value) => print(value),
            onSubmitted: (value) {
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

  Widget gridB(BuildContext context) => GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                //childAspectRatio: (MediaQuery.of(context).size.width / MediaQuery.of(context).size.height),
                //childAspectRatio: 0.5,
                mainAxisExtent: MediaQuery.of(context).size.height * 0.085,
              ),
    itemCount: 50,
    shrinkWrap: true,
    itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              decoration: BoxDecoration(
                //color: Colors.green,
                color: index < ind ? Colors.green : index == ind ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
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
      body: 
        Container(
          color: Colors.yellow,
          child: Column(
            children: [
              Padding(padding: EdgeInsets.all(16.0),
                child: gridB(context), 
              ),
              Row(children: [ 
                Padding(padding: EdgeInsets.all(5.0),),
                  Expanded(
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
