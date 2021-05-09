import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper{

  static final _databaseName = "EmgDatabase.db";
  static final _databaseVersion = 2;
  static final table = 'emgTable';

  static final columnSession = '_session';
  static final columnBicepsCH = 'bicepsCH';
  static final columnTripcepsCH = 'tricepsCH';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database _database;


  Future<Database> get database async{
    if(_database != null) return _database;

    _database = await _initDatabase();
    return _database;
  }
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnSession TEXT,
            $columnBicepsCH INTEGER,
            $columnTripcepsCH INTEGER
          )
          ''');
  }

  Future<void> insert (Session, BicepsCH, TricepsCH) async{
    final db = await database;

    await db.rawInsert(
        'INSERT INTO ${DatabaseHelper.table}'
            '(${DatabaseHelper.columnSession}, ${DatabaseHelper.columnBicepsCH}, ${DatabaseHelper.columnBicepsCH}) '
            'VALUES(?, ?, ?)', [Session, BicepsCH, TricepsCH]);
    //return res;
  }
  _insert() async {

  }
 // Future<List<Map <String, dynamic >>> getEmgReading() async{
  Future<List<Map <String, dynamic >>> getEmgReading() async{
    final db = await database;
    List<String> columnsToSelect=[DatabaseHelper.columnBicepsCH];
    List <Map <String, dynamic >> result = await db.query(
        DatabaseHelper.table,
        columns: columnsToSelect
    );

    return result;
  }



/*     IF YOU WATN TO QUERY DATA FROM A SELECTED ROW
  _query() async {
    // get a reference to the database
    Database db = await DatabaseHelper.instance.database;
    // get single row
    List<String> columnsToSelect = [
      DatabaseHelper.columnId,
      DatabaseHelper.columnName,
      DatabaseHelper.columnAge,
    ];
    String whereString = '${DatabaseHelper.columnId} = ?';
    int rowId = 1;
    List<dynamic> whereArguments = [rowId];
    List<Map> result = await db.query(
        DatabaseHelper.table,
        columns: columnsToSelect,
        where: whereString,
        whereArgs: whereArguments);
    // print the results
    result.forEach((row) => print(row));
    // {_id: 1, name: Bob, age: 23}
  }*/
}