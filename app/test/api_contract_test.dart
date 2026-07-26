// Bate na API de verdade (localhost:8080) pra provar o contrato ponta a ponta.
// Rode com o servidor Go no ar:
//   flutter test test/api_contract_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_platform/models/expense_model.dart';
import 'package:my_platform/services/api_client.dart';
import 'package:my_platform/services/auth_service.dart';
import 'package:my_platform/services/expense_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // O binding de teste estufa o HttpClient (tudo vira 400); aqui a graça é
  // justamente sair pra rede.
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final service = ExpenseService();

  test('login guarda o token e libera as rotas protegidas', () async {
    await expectLater(
      service.getAllExpenses(),
      throwsA(isA<UnauthorizedException>()),
      reason: 'sem token a API tem que recusar',
    );

    await AuthService.instance.login('teste@hhub.local', 'segredo123');
    expect(AuthService.instance.isLoggedIn.value, isTrue);

    final user = await AuthService.instance.me();
    expect(user.email, 'teste@hhub.local');
  });

  test('CRUD completo com valor em centavos e datas sem escorregar de dia', () async {
    final created = await service.saveExpense(
      expenseObj: ExpenseModel(
        name: 'Teste contrato',
        valueCents: ExpenseModel.centsFromReais(123.45),
        dateStart: DateTime(2026, 1, 1),
        dateEnd: DateTime(2026, 12, 31),
      ),
    );

    expect(created.id, isNotNull);
    expect(created.valueCents, 12345);
    expect(created.value, 123.45);
    expect(created.type, ExpenseModel.typeExit);
    // O fuso (-03:00) não pode empurrar a data pro dia anterior na ida e volta.
    expect(created.dateStart, DateTime(2026, 1, 1));
    expect(created.dateEnd, DateTime(2026, 12, 31));

    final updated = await service.saveExpense(
      expenseObj: ExpenseModel(
        id: created.id,
        name: 'Teste contrato editado',
        valueCents: 20000,
        isCredit: true,
      ),
    );
    expect(updated.id, created.id);
    expect(updated.name, 'Teste contrato editado');
    expect(updated.isCredit, isTrue);
    expect(updated.dateStart, isNull);

    final list = await service.getAllExpenses();
    expect(list.map((e) => e.id), contains(created.id));

    final total = await service.getTotal();
    final totalSemCredito = await service.getTotal(isCredit: false);
    expect(total, greaterThanOrEqualTo(totalSemCredito));

    await service.deleteExpense(created.id!);
    final afterDelete = await service.getAllExpenses();
    expect(afterDelete.map((e) => e.id), isNot(contains(created.id)));
  });

  test('token inválido cai como UnauthorizedException', () async {
    ApiClient.instance.setToken('nao-e-um-jwt');
    await expectLater(
      service.getAllExpenses(),
      throwsA(isA<UnauthorizedException>()),
    );
  });
}
