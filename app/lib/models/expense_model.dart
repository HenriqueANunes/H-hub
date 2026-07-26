class ExpenseModel {
  final int? id;
  final String name;

  /// A API guarda dinheiro em centavos (inteiro) — a conversão pra reais é só
  /// na borda, aqui. Nunca deixe um double virar a fonte da verdade do valor.
  final int valueCents;

  final DateTime? dateStart;
  final DateTime? dateEnd;
  final String type;
  final bool isCredit;

  const ExpenseModel({
    this.id,
    required this.name,
    required this.valueCents,
    this.dateStart,
    this.dateEnd,
    this.type = typeExit,
    this.isCredit = false,
  });

  /// Espelham o CHECK da tabela `expenses`.
  static const typeExit = 'exit';
  static const typeEntry = 'entry';

  /// Valor em reais, pra exibição e pros cálculos da tela.
  double get value => valueCents / 100;

  static int centsFromReais(double reais) => (reais * 100).round();

  /// Só os campos que a API aceita: `id` vem da URL e `user_id` vem do token.
  Map<String, dynamic> toJson() => {
    'name': name,
    'value_cents': valueCents,
    'date_start': _encodeDate(dateStart),
    'date_end': _encodeDate(dateEnd),
    'type': type,
    'is_credit': isCredit,
  };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json['id'] as int?,
    name: json['name'] as String,
    valueCents: json['value_cents'] as int,
    dateStart: _decodeDate(json['date_start']),
    dateEnd: _decodeDate(json['date_end']),
    type: json['type'] as String,
    isCredit: json['is_credit'] as bool,
  );
}

/// As colunas de data no Postgres não têm hora. Manda meia-noite em UTC pra o
/// fuso (-03:00) não empurrar a despesa pro dia anterior no caminho.
String? _encodeDate(DateTime? date) => date == null
    ? null
    : DateTime.utc(date.year, date.month, date.day).toIso8601String();

/// Lê só a parte de data e devolve o mesmo dia como data local, pelo mesmo
/// motivo — `toLocal()` aqui voltaria um dia.
DateTime? _decodeDate(Object? raw) {
  if (raw == null) return null;
  final parsed = DateTime.parse(raw as String);
  return DateTime(parsed.year, parsed.month, parsed.day);
}
