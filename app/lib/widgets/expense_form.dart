import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_platform/models/expense_model.dart';
import 'package:my_platform/services/currency_formatter.dart';
import 'package:my_platform/services/expense_service.dart';

class ExpenseForm extends StatefulWidget {
  final ExpenseModel? expense; // se vier, edita; se não, cria

  const ExpenseForm({super.key, this.expense});

  @override
  State<StatefulWidget> createState() => ExpenseFormState();
}

class ExpenseFormState extends State<ExpenseForm> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  bool _isCredit = false;
  DateTimeRange? _dateRange;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.expense != null) {
      // edição
      _name.text = widget.expense!.name;
      _value.text = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
          .format(widget.expense!.value);
      _isCredit = widget.expense!.isCredit;

      if (widget.expense!.date_start != null) {
        _dateRange = DateTimeRange(
          start: widget.expense!.date_start!,
          end: widget.expense!.date_end ?? widget.expense!.date_start!,
        );
      }
    } else {
      // novo
      _value.text = 'R\$ 0,00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStart = _dateRange?.start;
    final dateEnd = _dateRange?.end;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Title
            TextFormField(
              controller: _name,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Nome da despesa',
              ),
              validator: (value) {
                if (value == '') {
                  return 'É necessário preencher o nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            // Amount
            TextFormField(
              controller: _value,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor da despesa',
              ),
              inputFormatters: [
                CurrencyInputFormatter(),
              ],
              validator: (value) {
                if (value == 'R\$ 0,00') {
                  return 'É necessário preencher o valor';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            // Initial Date
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateStart != null && dateEnd != null
                        ? 'Data inicial: ${DateFormat('dd/MM/yyyy').format(dateStart)}\n'
                          'Data final: ${DateFormat('dd/MM/yyyy').format(dateEnd)}'
                        : 'Selecione uma data',
                  ),
                ),
                IconButton(
                  onPressed: pickDateRange,
                  icon: const Icon(Icons.calendar_month),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            CheckboxListTile(
              title: const Text('É Crédito?'),
              value: _isCredit,
              onChanged: (value) {
                setState(() {
                  _isCredit = value!;
                });
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()){
                  _saveExpense();
                }
              },
              icon: const Icon(Icons.save),
              label: Text(widget.expense == null ? 'Salvar' : 'Atualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickDateRange() async {
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (newDateRange != null) {
      setState(() => _dateRange = newDateRange);
    }
  }

  _saveExpense() {
    final dateStart = _dateRange?.start;
    final dateEnd = _dateRange?.end;
    final cleanValue = _value.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    final expense = ExpenseModel(
      id: widget.expense?.id,
      name: _name.text,
      value: double.tryParse(cleanValue) ?? 0.0,
      date_start: dateStart,
      date_end: dateEnd,
      type: 'exit',
      isCredit: _isCredit,
    );

    // add it to database.
    ExpenseService().saveExpense(expenseObj: expense);

    // close the bottomsheet
    Navigator.of(context).pop(true);
  }
}
