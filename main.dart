import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;


enum SortState { sidIncreasing, sidDecreasing, gradeIncreasing, gradeDecreasing }

class Grade {
  String sid;
  String grade;
  Grade({required this.sid, required this.grade});
}

List<Grade> grades = [
  Grade(sid: "123456789", grade: "A"),
  Grade(sid: "987654321", grade: "B"),
  Grade(sid: "234567890", grade: "C"),
  Grade(sid: "345678901", grade: "D"),
  Grade(sid: "456789012", grade: "B+"),
  Grade(sid: "567890123", grade: "A-"),

];



void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grades App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ListGrades(),
    );
  }
}

class ListGrades extends StatefulWidget {
  @override
  _ListGradesState createState() => _ListGradesState();
}

class _ListGradesState extends State<ListGrades> {
  void _editGrade(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final sidController = TextEditingController(text: grades[index].sid);
        final gradeController = TextEditingController(text: grades[index].grade);
        return AlertDialog(
          title: Text('Edit Grade'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: sidController,
                decoration: InputDecoration(labelText: 'SID'),
              ),
              TextField(
                controller: gradeController,
                decoration: InputDecoration(labelText: 'Grade'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  grades[index] = Grade(sid: sidController.text, grade: gradeController.text);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  void _sortGrades(SortState sortState) {
    setState(() {
      if (sortState == SortState.sidIncreasing) {
        grades.sort((a, b) => a.sid.compareTo(b.sid));
      } else if (sortState == SortState.sidDecreasing) {
        grades.sort((a, b) => b.sid.compareTo(a.sid));
      } else if (sortState == SortState.gradeIncreasing) {
        grades.sort((a, b) => a.grade.compareTo(b.grade));
      } else { // SortState.gradeDecreasing
        grades.sort((a, b) => b.grade.compareTo(a.grade));
      }
    });
  }
  Widget _buildBarChart(List<Grade> grades) {
    final gradeFrequencies = _calculateGradeFrequencies(grades);
    final barGroups = _createBarGroups(gradeFrequencies);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: gradeFrequencies.values.reduce(max).toDouble(),
        titlesData: FlTitlesData(
          bottomTitles: SideTitles(
            showTitles: true,
            getTextStyles: (context, value) => const TextStyle(color: Color(0xff939393), fontSize: 10),
            margin: 10,
            getTitles: (double value) {
              return gradeFrequencies.keys.elementAt(value.toInt());
            },
          ),
          leftTitles: SideTitles(showTitles: true),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        barGroups: barGroups,
      ),
    );
  }
  //Frequency Function
  Map<String, int> _calculateGradeFrequencies(List<Grade> grades) {
    Map<String, int> frequencies = {
    };
    for (var grade in grades) {
      frequencies.update(grade.grade, (value) => ++value, ifAbsent: () => 1);
    }
    return frequencies;
  }
  List<BarChartGroupData> _createBarGroups(
      Map<String, int> gradeFrequencies) {
    final List<BarChartGroupData> barGroups = [];
    final sortedKeys = gradeFrequencies.keys.toList()
      ..sort();
    for (var i = 0; i < sortedKeys.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              y: gradeFrequencies[sortedKeys[i]]!.toDouble(),
              colors: [Colors.blue],
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    return barGroups;
  }

  void _showGradeStatistics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(16),
          child: _buildBarChart(grades),
        );
      },
    );
  }


  Future<void> _importCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final fileBytes = result.files.single.bytes;
      final csvString = String.fromCharCodes(fileBytes!);
      _processCsvData(csvString);
    }
  }
  String _calculateAverageGrade() {
    // Define a map from letter grades to numeric values
    final Map<String, double> gradeValues = {
        'A  ': 4.0,
        'A-': 3.7,
        'B+': 3.3,
        'B': 3.0,
        'B-': 2.7,
        'C+': 2.3,
        'C': 2.0,
        'C-': 1.7,
        'D+': 1.3,
        'D': 1.0,
        'F': 0.0,
    };


    double sum = grades.fold(0.0, (previousValue, grade) {
      double value = gradeValues[grade.grade] ?? 0.0;
      return previousValue + value;
    });

    // Calculate the average
    if (grades.isEmpty) return 'N/A'; 
    double average = sum / grades.length;

    return average.toStringAsFixed(2); 
  }

  void _exportGradesToCsv() {
    final rows = [
      ["SID", "Grade"],
      ...grades.map((grade) => [grade.sid, grade.grade]).toList(),
    ];

    String csv = const ListToCsvConverter().convert(rows);
    // Create a blob from the CSV string
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "grades_exported.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
  void _confirmExport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Export Grades'),
          content: Text('Do you want to export to a CSV file?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Export'),
              onPressed: () {
                Navigator.of(context).pop(); 
                _exportGradesToCsv(); 
              },
            ),
          ],
        );
      },
    );
  }

  void _processCsvData(String csvString) {
    List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvString);

    setState(() {
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        var row = rowsAsListOfValues[i];
        if (row.length < 2) continue;

        String sid = row[0].toString();
        String grade = row[1].toString();
        grades.add(Grade(sid: sid, grade: grade));
      }


    }
    );

  }
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.sort_by_alpha),
                title: Text('SID Increasing'),
                onTap: () {
                  _sortGrades(SortState.sidIncreasing);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.sort_by_alpha),
                title: Text('SID Decreasing'),
                onTap: () {
                  _sortGrades(SortState.sidDecreasing);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.sort),
                title: Text('Grade Increasing'),
                onTap: () {
                  _sortGrades(SortState.gradeIncreasing);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.sort),
                title: Text('Grade Decreasing'),
                onTap: () {
                  _sortGrades(SortState.gradeDecreasing);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
        
      },

    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List of Grades'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () => _showGradeStatistics(context),
          ),
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: () {
              String avgGrade = _calculateAverageGrade();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Average Grade"),
                    content: Text("The average grade is $avgGrade"),
                    actions: [
                      TextButton(
                        child: Text('OK'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ); 
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _importCsv,
          ),
          IconButton(
            icon: Icon(Icons.import_contacts),
            onPressed: _confirmExport,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: grades.length,
        itemBuilder: (context, index) {
          final grade = grades[index];
          return Dismissible(
            key: Key(grade.sid),
            background: Container(color: Colors.red),
            onDismissed: (direction) {
              setState(() {
                grades.removeAt(index);
              });
            },
            child: GestureDetector(
              onLongPress: () => _editGrade(index),
              child: ListTile(
                title: Text('SID: ${grade.sid}'),
                subtitle: Text('Grade: ${grade.grade}'),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? isGradeAdded = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GradeForm()),
          );
          if (isGradeAdded != null && isGradeAdded) {
            setState(() {});
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  getApplicationDocumentsDirectory() {}
}



class GradeForm extends StatefulWidget {
  @override
  _GradeFormState createState() => _GradeFormState();
}

class _GradeFormState extends State<GradeForm> {
  final _formKey = GlobalKey<FormState>();
  final sidController = TextEditingController();
  final gradeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Grade'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: sidController,
                keyboardType: TextInputType.number,
                maxLength: 9,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the SID';
                  } else if (value.length != 9) {
                    return 'SID must be 9 digits long';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'SID',
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: gradeController,
                decoration: InputDecoration(
                  labelText: 'Grade',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Grade';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      grades.add(Grade(sid: sidController.text, grade: gradeController.text));
                    });
                    Navigator.pop(context, true);
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
