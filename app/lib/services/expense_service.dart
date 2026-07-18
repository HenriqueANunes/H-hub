import 'package:my_platform/models/database_model.dart';
import 'package:my_platform/models/expense_model.dart';

class ExpenseService {

  Future<int> saveExpense({required ExpenseModel expenseObj}) async {
    final db = await DatabaseModel.instance.getDatabase();

    if (expenseObj.id != null) {
      return await db.update(
        'expenses',
        expenseObj.toMap(),
        where: 'id = ?',
        whereArgs: [expenseObj.id]
      );
    } else {
      return await db.insert(
        'expenses',
        expenseObj.toMap(),
        // conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
  }

  Future<List<ExpenseModel?>> getAllExpenses() async {
    final db = await DatabaseModel.instance.getDatabase();
    final dateNow = DateTime.now().millisecondsSinceEpoch;
    var result = await db.query(
      'expenses',
      orderBy: 'id ASC',
      where: '((date_start <= ? and date_end >= ?) or date_start is null or date_end is null)',
      whereArgs: [dateNow, dateNow],
    );
    return result.map((json) => ExpenseModel.fromJson(json)).toList();
  }

  Future<double> getTotal({isCredit = true}) async {
    final db = await DatabaseModel.instance.getDatabase();
    final dateNow = DateTime.now().millisecondsSinceEpoch;

    String filter = '';
    if (!isCredit){
      filter = ' and not is_credit';
    }

    var result = await db.query(
      'expenses',
      columns: ['sum(value) as total'],
      orderBy: 'id ASC',
      where: '((date_start <= ? and date_end >= ?) or date_start is null or date_end is null) $filter',
      whereArgs: [dateNow, dateNow],
    );
    return result[0]['total'] == null ? 0.0 : double.parse(result[0]['total'].toString());
  }

  Future<bool> deleteExpense(int id) async {
    final db = await DatabaseModel.instance.getDatabase();
    var result = await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result != 0){
      return true;
    } else {
      return false;
    }

  }
}
