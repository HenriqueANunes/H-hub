import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_platform/widgets/expense_form.dart';
import 'package:my_platform/widgets/expense_tile.dart';
import 'package:my_platform/widgets/app_bar_footer.dart';
import 'package:my_platform/services/expense_service.dart';
import 'package:my_platform/models/expense_model.dart';

class ListExpensesPage extends StatefulWidget {
  const ListExpensesPage({super.key});

  @override
  State<StatefulWidget> createState() => ExpensesList();
}

class ExpensesList extends State<ListExpensesPage> {
  final _expenseObj = ExpenseService();
  late Future<List<ExpenseModel?>> _expensesList;
  late Future<double> _expensesTotal;

  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    _expensesList = _expenseObj.getAllExpenses(); // Initialize your future in initState
    _expensesTotal = _expenseObj.getTotal();
  }

  void _refreshData() {
    setState(() {
      _expensesList = _expenseObj.getAllExpenses(); // Assign a new Future to trigger rebuild
      _expensesTotal = _expenseObj.getTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas cadastradas'),
      ),
      body: FutureBuilder<List<ExpenseModel?>>(
        future: _expensesList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Center(child: Text('$error'));
            } else {
              final expensesList = snapshot.data;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.separated(
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 8);
                  },
                  itemCount: expensesList == null ? 0 : expensesList.length,
                  itemBuilder: (context, index) {
                    final expense = expensesList![index];
                    return expenseTile(context, expense!, theme, _refreshData);
                  },
                ),
              );
            }
          } else {
            return const Center(child: Text('teste'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final status = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ExpenseForm(),
          );
          if (status == true) {
            _refreshData();
          }
        },
        tooltip: 'Cadatrar Despesa',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: FutureBuilder<double?>(
        future: _expensesTotal,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Center(child: Text('$error'));
            } else {
              final expenseTotal = snapshot.data;
              return AppFooter(
                child: Center(
                  child: Text(
                    _formatter.format(expenseTotal),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              );
            }
          } else {
            return const Center(child: Text('teste'));
          }
        },
      ),
    );
  }
}
