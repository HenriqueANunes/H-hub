import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_platform/models/expense_model.dart';
import 'package:my_platform/widgets/expense_form.dart';
import 'package:my_platform/services/api_client.dart';
import 'package:my_platform/services/expense_service.dart';

Widget expenseTile(BuildContext context, ExpenseModel expense, ThemeData theme, VoidCallback onRefresh) {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final _expenseObj = ExpenseService();

  void _deleteExpense() {
    // Guardado antes do await: depois dele o context do diálogo já morreu.
    final messenger = ScaffoldMessenger.of(context);

    showDialog(context: context, builder: (dialogContext) {
      return AlertDialog(
        title: Text('Deletar Despesa'),
        content: Text('Tem certeza que você quer deletar essa despesa?'),
        actions: [
          MaterialButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _expenseObj.deleteExpense(expense.id!);
                onRefresh();
              } on ApiException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
            child: Text('Sim'),
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: Text('Não'),
          ),
        ],
      );
    });
  }

  return ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    tileColor: theme.cardColor,
    leading: const Icon(Icons.trending_down),
    title: Text(expense.name),
    subtitle: Text(_formatter.format(expense.value)),
    trailing: ElevatedButton(
      onPressed: _deleteExpense,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      child: Icon(
        Icons.delete,
        color: Colors.redAccent,
      ),
    ),
    onTap: () async {
      final status = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ExpenseForm(expense: expense),
      );
      if (status == true) {
        onRefresh();
      }
    },
  );
}
