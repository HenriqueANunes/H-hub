import 'package:my_platform/models/expense_model.dart';
import 'package:my_platform/services/api_client.dart';

class ExpenseService {
  final ApiClient _api = ApiClient.instance;

  /// Só as despesas vigentes hoje — o filtro de vigência, que era SQL aqui no
  /// cliente, agora é do servidor (`?active=true`).
  Future<List<ExpenseModel>> getAllExpenses() async {
    final data = await _api.get('/expenses', query: {'active': 'true'});
    return (data as List)
        .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Total das vigentes, em reais. `isCredit: false` tira as faturas de cartão.
  Future<double> getTotal({bool isCredit = true}) async {
    final data = await _api.get(
      '/expenses/total',
      query: {'credit': isCredit.toString()},
    );
    return (data['total_cents'] as int) / 100;
  }

  /// Cria quando não tem `id`, atualiza quando tem. Devolve a despesa como o
  /// servidor a guardou.
  Future<ExpenseModel> saveExpense({required ExpenseModel expenseObj}) async {
    final data = expenseObj.id == null
        ? await _api.post('/expenses', expenseObj.toJson())
        : await _api.put('/expenses/${expenseObj.id}', expenseObj.toJson());
    return ExpenseModel.fromJson(data as Map<String, dynamic>);
  }

  /// Lança `ApiException` se falhar (404 quando a despesa não é do usuário).
  Future<void> deleteExpense(int id) => _api.delete('/expenses/$id');
}
