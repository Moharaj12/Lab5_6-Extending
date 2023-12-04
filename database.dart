import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'package:path/path.dart';


class Grade {
  int? id;
  String sid;
  String grade;

  Grade({this.id, required this.sid, required this.grade});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sid': sid,
      'grade': grade,
    };
  }

  static Grade fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'],
      sid: map['sid'],
      grade: map['grade'],
    );
  }
}

class GradesModel {
  static final _databaseName = "gradesDatabase.db";
  static final _databaseVersion = 1;

  static final table = 'grades';

  static final columnId = 'id';
  static final columnSid = 'sid';
  static final columnGrade = 'grade';


  GradesModel._privateConstructor();

  static final GradesModel instance = GradesModel._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnSid TEXT NOT NULL,
            $columnGrade TEXT NOT NULL
          )
          ''');
  }

  // Define methods for CRUD operations here...

  // Insert
  Future<int> insertGrade(Grade grade) async {
    Database db = await this.database;
    int id = await db.insert(table, grade.toMap());
    return id;
  }

  // Retrieve all grades
  Future<List<Grade>> getAllGrades() async {
    Database db = await this.database;
    List<Map<String, dynamic>> maps = await db.query(
        table, columns: [columnId, columnSid, columnGrade]);
    return maps.map((map) => Grade.fromMap(map)).toList();
  }


  // Update
  Future<int> updateGrade(Grade grade) async {
    Database db = await this.database;
    return await db.update(table, grade.toMap(),
        where: '$columnId = ?', whereArgs: [grade.id]);
  }

  // Delete
  Future<int> deleteGradeById(int id) async {
    Database db = await this.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

}
