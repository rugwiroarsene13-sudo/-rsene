
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

class StockDatabase {
  static Database? _database;

  static final StoreRef<int, Map<String, dynamic>> _store =
      intMapStoreFactory.store('products');

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await databaseFactoryWeb.openDatabase(
      'stock_management.db',
    );

    return _database!;
  }

  static Future<int> addProduct(Map<String, dynamic> product) async {
    final db = await database;
    return _store.add(db, product);
  }

  static Future<List<RecordSnapshot<int, Map<String, dynamic>>>>
      getProducts() async {
    final db = await database;
    return _store.find(db);
  }

  static Future<void> updateProduct(
    int id,
    Map<String, dynamic> product,
  ) async {
    final db = await database;
    await _store.record(id).put(db, product);
  }

  static Future<void> deleteProduct(int id) async {
    final db = await database;
    await _store.record(id).delete(db);
  }
}
