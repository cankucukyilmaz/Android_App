import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:async/async.dart';
import 'package:share_plus/share_plus.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

import 'package:universal_html/html.dart' hide Text, File, Navigator;
import 'dart:io';
import 'package:path/path.dart' as Path;
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import 'package:permission_handler/permission_handler.dart';
//import 'package:starflut/starflut.dart';

File? file;
File? jsonFile;
late List<List<dynamic>> rawData = [];
late List _items = [];
late List<MyData> myData = []; //List to store data converted
String jsonString = "";

//Top level function required to be defined outside of classes to isolare process
Excel parseExcelFile(List<int> bytes) {
  return Excel.decodeBytes(bytes);
}

const initialAssetFile = 'assets/data_used.json';
const localFilename = 'data_used.json';

class Repository {
  /// Initially check if there is already a local file.
  /// If not, create one with the contents of the initial json in assets
  Future<File> _initializeFile() async {
    final localDirectory = '/sdcard/Download';
    final file = File('$localDirectory/$localFilename');

    if (!await file.exists()) {
      // read the file from assets first and create the local file with its contents
      final initialContent = await rootBundle.loadString(initialAssetFile);
      await file.create();
      await file.writeAsString(initialContent);
    }

    return file;
  }

  Future<String> readFile() async {
    final file = await _initializeFile();
    //print('reading $file');
    var status = await Permission.storage.status;
    //print(status.isGranted);
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    return await file.readAsString();
  }

  Future<void> writeToFile(String data) async {
    final file = await _initializeFile();
    //print('writing $file');
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    await file.writeAsString(data);
    //print(data);
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Data declared here

  @override
  Widget build(BuildContext context) {
    //Used to display the current file (if there is any selected) on the main home screen
    final fileName =
        file != null ? Path.basename(file!.path) : 'No File Selected';

    //initialize Repository
    //File androidFile = Repository()._initializeFile() as File; //Maybe?
    //print(Repository().readFile().toString()); //TRY

    return Scaffold(
      // ---------------- APP BAR DISPLAY ------------------------
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 72, 144),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(13.0),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Welcome',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser!.displayName!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            new Spacer(),
            Image.asset(
              'assets/sabanci_logo.jpg',
              fit: BoxFit.contain,
              height: 40,
            ),
          ],
        ),
      ),
      // ----------------- BODY ----------------------
      body: Container(
        padding: EdgeInsets.all(32),
        color: Colors.white,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // -------------- RECEIVE DATA FROM CYTON BOARD BUTTON -------------
            Container(
              width: 260,
              child: MaterialButton(
                padding: const EdgeInsets.all(10),
                color: const Color.fromARGB(255, 0, 72, 144),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.data_object,
                      color: Colors.white,
                      size: 20,
                    ),
                    //new Spacer(),
                    const SizedBox(width: 10),
                    const Text(
                      'RECEIVE DATA FROM BOARD',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                onPressed: () async {
                  //Get Data from Cyton Board
                  List<MyData> fetchData() {
                    return myData =
                        http.get(Uri.parse('http://127.0.0.1:5000/GetData'))
                            as List<MyData>;
                  }
                },
              ),
            ),
            // -------------- ADD CSV FILE BUTTON -------------
            Container(
              width: 260,
              child: MaterialButton(
                padding: const EdgeInsets.all(10),
                color: const Color.fromARGB(255, 0, 72, 144),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file,
                      color: Colors.white,
                      size: 20,
                    ),
                    //new Spacer(),
                    const SizedBox(width: 30),
                    const Text(
                      'ADD CSV / XLSX FILE',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                onPressed: () async {
                  //SelectFile will give the option to choose a csv/xlmx file
                  await selectFile();
                },
              ),
              // -------------------- TEXT SHOWING FILE NAME -------------------
            ),
            Container(
              width: 260,
              color: Colors.transparent,
              child: Text(
                fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            // ---------------- CONVERT FILE ---------------------------
            Container(
              width: 260,
              child: MaterialButton(
                padding: const EdgeInsets.all(10),
                color: const Color.fromARGB(255, 0, 72, 144),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.list,
                      color: Colors.white,
                      size: 20,
                    ),
                    //new Spacer(),
                    const SizedBox(width: 20),
                    const Text(
                      'CONVERT FILE TO LIST',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                onPressed: () async {
                  //Converts the current file to a displayable/sendable list
                  //Check if file is Excel or not
                  final mimeType = lookupMimeType(file!.path);
                  //print(mimeType);
                  //Checks if the type of file uploaded is Excel or not
                  if (mimeType ==
                      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
                    //XLSX
                    //print("xlsx file");
                    jsonString = await excelToJson()
                        as String; //Differing function call if xlsx
                  } else if (mimeType == 'text/csv') {
                    //CSV
                    //print("csv file");
                    jsonString = await excelToJson() as String;
                  } else {
                    //print("Not csv or xlsx");
                    await file!.readAsString().then((String contents) {
                      jsonString = contents;
                    });
                  }

                  //print('jsonString $jsonString');

                  //use jsonString value and save to data_used.json
                  Repository().writeToFile(
                      jsonString); // Writes to data_used.json on our android device

                  //Read the Json file
                  readJson();
                },
              ),
            ),
            // -------------- CREATE A CHART & GO TO CHART PAGE -------------
            Container(
              width: 260,
              child: MaterialButton(
                padding: const EdgeInsets.all(10),
                color: const Color.fromARGB(255, 0, 72, 144),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.create,
                      color: Colors.white,
                      size: 20,
                    ),
                    //new Spacer(),
                    const SizedBox(width: 40),
                    const Text(
                      'CREATE CHART',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                onPressed: () async {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ResultPage()));
                },
              ),
            ),
            // -------------- SHARE DATA FILE BUTTON ------------------
            Container(
              width: 260,
              child: MaterialButton(
                padding: const EdgeInsets.all(10),
                color: const Color.fromARGB(255, 0, 72, 144),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 20,
                    ),
                    //new Spacer(),
                    const SizedBox(width: 50),
                    const Text(
                      'SHARE DATA',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles();
                  final files = result!.files.map((file) => file.path).toList();
                  var withoutNulls =
                      List<String>.from(files.where((c) => c != null));
                  await Share.shareFiles(withoutNulls,
                      text: 'Data file is attached');
                },
              ),
            ),
            SizedBox(height: 100),
            // -------------- LOG OUT BUTTON ------------------
            Container(
              width: 130,
              child: MaterialButton(
                padding: const EdgeInsets.all(10),
                color: const Color.fromARGB(255, 0, 72, 144),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                    //new Spacer(),
                    const SizedBox(width: 10),
                    const Text(
                      'LOG OUT',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                onPressed: () {
                  AuthService().signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //JSON region
  Future<void> readJson() async {
    //print('file $file');
    //print('filepath');
    //print(file!.path);

    var pos = file!.path.lastIndexOf('/');
    String filePath_section =
        (pos != 1) ? file!.path.substring(pos, file!.path.length) : file!.path;

    //print('filePath_section $filePath_section');

    final String response =
        await rootBundle.loadString('assets$filePath_section');

    //Code above was for testing purposes, unneeded as we have stored the json locally on the device at /sdcard/Downloads/data_used
    final data = await json
        .decode(jsonString); //Taking from jsonString so response is unused
    setState(() {
      _items = data; //same thing
    });

    await iterateJsonData();
  }

  Future<void> iterateJsonData() async {
    //Need to save items from here to myData
    if (_items.isNotEmpty) {
      for (int i = 0; i < _items.length; i++) //We want to iterate through items
      {
        //myData[i].time = _items[i]["time_c"];
        //myData[i].value = _items[i]["ECG data"];

        //print(_items[i]["time_c"]);
        //print(_items[i]["ECG data"]);
        var tempTimeVal = (_items[i][
            "time_c"]); //Value with , and "" needs to be changed to be a double
        var tempValueVal = (_items[i]["ECG data"]);
        //These vals are almost always string except when it is a whole number: need to check for that exception

        String tempTimeString = "";
        String tempValueString = "";

        switch (tempTimeVal.runtimeType) {
          case String:
            {
              tempTimeString = tempTimeVal;
            }
            break;
          case int:
            {
              tempTimeString = tempTimeVal.toString();
            }
            break;
          default:
            {
              tempTimeString = tempTimeVal;
            }
            break;
        }

        //Same for Value in the case of an int
        switch (tempValueVal.runtimeType) {
          case String:
            {
              tempValueString = tempValueVal;
            }
            break;
          case int:
            {
              tempValueString = tempValueVal.toString();
            }
            break;
          default:
            {
              tempValueString = tempValueVal;
            }
            break;
        }

        //adapt both of these
        tempTimeString = tempTimeString.replaceAll(",", ".");
        tempValueString = tempValueString.replaceAll(",", ".");

        //print('ttStr $tempTimeString');
        //print('tvStr $tempValueString');

        double tempTime = double.parse(tempTimeString);
        double tempValue = double.parse(tempValueString);

        MyData tempData2 = MyData(tempTime, tempValue);
        //tempData = MyData((_items[i]["time_c"]),
        //    (_items[i]["ECG data"])); //Update the data for this case

        myData.add(tempData2);
      }
    } else {
      throw ArgumentError("No Items Detected");
    }

    //print("done");
  }

  Future<String> excelToJson() async {
    String excelFilePath;
    File? excelFile = file;

    excelFilePath = excelFile!.path;

    var bytes = await File(excelFilePath).readAsBytes();
    Excel excel = await compute(parseExcelFile, bytes);
    int i = 0;
    List<dynamic> keys = [];
    var jsonMap = [];

    for (var table in excel.tables.keys) {
      //print(table.toString());
      for (var row in excel.tables[table]!.rows) {
        //print(row.toString());
        if (i == 0) {
          keys = row;
          i++;
        } else {
          var temp = {};
          int j = 0;
          String tk = '';
          for (var key in keys) {
            tk = '\"${key.toString()}\"';
            temp[tk] = (row[j].runtimeType == String)
                ? '\"${row[j].toString()}\"'
                : row[j];
            j++;
          }

          jsonMap.add(temp);
        }
      }
    }
    print(
      jsonMap.length.toString(),
    );
    print(jsonMap.toString());
    String fullJson =
        jsonMap.toString().substring(1, jsonMap.toString().length - 1);
    print(
      fullJson.toString(),
    );
    return fullJson;
  }

  //must be within this class to utilize the file variables
  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);

    if (result == null) return;
    final path = result.files.single.path!;

    setState(() => file = File(path));

    //Test convert data
    /*
    final input = File(path).openRead();

    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    setState(() {
      rawData = fields; //here we get the rawData as a List<List<dynamic>>
    });
    */
  }

  Future<List<MyData>> getListFromExcel(File file) async {
    List<int> bytes = await file.readAsBytes();
    Excel excelFile = await compute(parseExcelFile, bytes);
    //Excel excelFile = Excel.decodeBytes(await file.readAsBytes());

    if (excelFile.sheets.isEmpty) {
      throw ArgumentError("Excel file has no sheets");
    }
    Sheet excelSheet = excelFile.sheets.values.first;
    return excelSheet.rows.map<MyData>((List<Data?> row) {
      if (row[0] == null || row[1] == null) {
        throw ArgumentError("Excel file contains empty cells");
      } else {
        return MyData(row[0]!.value, double.parse(row[1]!.value));
      }
    }).toList();
  }

  /*
  Future<List<MyData>> getListFromExcel(File file) async {
    final input = File(file.path).openRead();

    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    print(fields);

    setState(() {
      rawData = fields; //here we get the rawData as a List<List<dynamic>>
    });

    print(rawData[0]);
    print(rawData[1]);

    return myData;
  }
  */

  //Test getList function
  /*
  Future<List<MyData>> getListFromExcel(File file) async {
    Excel excelFile = Excel.decodeBytes(await file.readAsBytes());
    if (excelFile.sheets.isEmpty) {
      throw ArgumentError("No Sheets detected in Excel folder");
    }
    Sheet excelSheet = excelFile.sheets.values.first;
    return excelSheet.rows.map<MyData>((List<Data?> row) {
      if (row[0] == null || row[1] == null) {
        throw ArgumentError("Empty cells detected in Excel Sheet");
      } else {
        return MyData(row[0]!.value, double.parse(row[1]!.value));
      }
    }).toList();
  }
  */

  /*
  Future<List<MyData>> getListFromExcel(File file) async {
    //var bytes = File(file.path).readAsBytesSync();
    //var excel = Excel.decodeBytes(bytes);

    var bytes = await file.readAsBytes();
    var excel = await compute(parseExcelFile, bytes);

    if (excel.sheets.isEmpty) {
      throw ArgumentError('Excel file contains no sheets');
    }

    Sheet excelSheet = excel.sheets.values.first;

    return excelSheet.rows.map<MyData>((List<Data?> row) {
      if (row[0] == null || row[1] == null) {
        throw ArgumentError("Excel file contains empty cells");
      } else {
        return MyData(row[0]!.value, double.parse(row[1]!.value));
      }
    }).toList();

    //int rowCount = 0;
    /*
    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows) {
        tempList[rowCount].time = double.parse(row[0].toString());
        tempList[rowCount].value = double.parse(row[1].toString());

        if (rowCount < 20) {
          print(tempList[rowCount].time);
          print(tempList[rowCount].value);
        }

        rowCount++;
      }
    }

    */
  }
  */
}

class ResultPage extends StatefulWidget {
  const ResultPage({Key? key}) : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late ChartSeriesController _chartSeriesController;

  @override
  void initState() {
    //Timer.periodic(const Duration(seconds: 1), updateDataSource);
    super.initState();
  }

  double time = 0;

  /*
  void updateDataSource(Timer timer) {
    time = time + 1; //incrementing time
    _HomePageState().myData.add(MyData(
        _HomePageState().myData[time.toInt()].time,
        _HomePageState()
            .myData[time.toInt()]
            .value)); //Adding myData as time and value (convering to int)
    _HomePageState().myData.removeAt(
        0); //decreases size by one and moves everything down one position

    _chartSeriesController.updateDataSource(
        addedDataIndex: _HomePageState().myData.length - 1,
        removedDataIndex: 0);
  }
  */

  @override
  Widget build(BuildContext context) {
    File? currFile = file;
    //String currFileName = Path.basename(currFile!.path);

    final currFileName =
        currFile != null ? Path.basename(currFile.path) : 'No File Selected';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 72, 144),
        automaticallyImplyLeading: false,
        leading: Row(
          children: [
            new IconButton(
              icon: new Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: (() => Navigator.of(context)
                  .pop()), //Takes us back to the HomePage by popping
            ),
          ],
        ),
        title: Text(
          'Chart of $currFileName',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SfCartesianChart(
        series: <LineSeries<MyData, double>>[
          LineSeries<MyData, double>(
            onRendererCreated: (ChartSeriesController controller) {
              _chartSeriesController = controller;
            },
            dataSource: myData,
            color: const Color.fromARGB(255, 0, 72, 144),
            xValueMapper: (MyData ekg, _) => ekg.time,
            yValueMapper: (MyData ekg, _) => ekg.value,
          )
        ],
        primaryXAxis: NumericAxis(
          majorGridLines: const MajorGridLines(width: 0),
          edgeLabelPlacement: EdgeLabelPlacement.shift,
          interval: 3,
          title: AxisTitle(text: 'Time / s'),
        ),
        primaryYAxis: NumericAxis(
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            title: AxisTitle(text: 'ECG Value')),
      ),
    );
  }
}

class MyData {
  //Time and value data from our ECG Results
  double time;
  double value;
  MyData(this.time, this.value);
}

//Previous test code:
/*
class _HomePageState extends State<HomePage> {
  //String? user = FirebaseAuth.instance.currentUser!.email ?? FirebaseAuth.instance.currentUser!.displayName;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              FirebaseAuth.instance.currentUser!.displayName!,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              FirebaseAuth.instance.currentUser!.email!,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(
              height: 30,
            ),
            MaterialButton(
              padding: const EdgeInsets.all(10),
              color: Color.fromARGB(255, 0, 72, 144),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              child: const Text(
                'LOG OUT',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              onPressed: () {
                AuthService().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
*/
